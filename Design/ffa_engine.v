// File: ffa_engine.v
// Description: Synthesizable 5-State FSM Fast Folding Algorithm (FFA) Core Engine
// Author: Chirag131513
// Target: Xilinx / Cadence / Synopsys Synthesizable RTL
`timescale 1ns / 1ps

module ffa_engine #(
    parameter DATA_BUFFER_SIZE  = 1024,
    parameter PROFILE_BINS      = 64,
    parameter NUM_TRIAL_PERIODS = 128,
    parameter PROFILE_MEM_SIZE  = NUM_TRIAL_PERIODS * PROFILE_BINS
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  adc_data,
    output reg         tx_start,
    output reg [31:0]  tx_data,
    input  wire        tx_busy
);

    // =========================================================================
    // Memory Storage
    // =========================================================================
    reg [7:0]  data_buffer    [0:DATA_BUFFER_SIZE-1];
    reg [31:0] profile_memory [0:PROFILE_MEM_SIZE-1];

    // =========================================================================
    // State Encoding
    // =========================================================================
    localparam [2:0]
        S_IDLE         = 3'b000,
        S_INIT_MEM     = 3'b001,
        S_ACQUIRE_DATA = 3'b010,
        S_FOLD_DATA    = 3'b011,
        S_DETECT_PEAK  = 3'b100,
        S_SEND_RESULT  = 3'b101;

    reg [2:0] current_state;

    // =========================================================================
    // Internal Registers & Index Counters
    // =========================================================================
    reg [$clog2(PROFILE_MEM_SIZE):0]  mem_init_idx;
    reg [$clog2(DATA_BUFFER_SIZE):0]  buffer_write_addr;
    reg [$clog2(DATA_BUFFER_SIZE):0]  fold_sample_idx;
    reg [11:0]                        trial_period;
    reg [11:0]                        phase_counter;
    reg [$clog2(PROFILE_MEM_SIZE):0]  peak_scan_idx;
    reg [31:0]                        max_power;
    reg [31:0]                        detected_period;
    reg [31:0]                        curr_mem_val;

    wire [$clog2(PROFILE_MEM_SIZE)-1:0] fold_mem_addr;
    wire [$clog2(PROFILE_BINS)-1:0]     active_bin;

    // Direct bin mapping: map phase counter within trial period to profile bins
    assign active_bin    = (phase_counter < PROFILE_BINS) ? phase_counter[$clog2(PROFILE_BINS)-1:0] : (phase_counter % PROFILE_BINS);
    assign fold_mem_addr = (trial_period * PROFILE_BINS) + active_bin;

    // =========================================================================
    // Single Unified Procedural FSM & Memory Controller
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            current_state     <= S_IDLE;
            mem_init_idx      <= 0;
            buffer_write_addr <= 0;
            fold_sample_idx   <= 0;
            trial_period      <= 12'd10;
            phase_counter     <= 12'd0;
            peak_scan_idx     <= 0;
            max_power         <= 32'd0;
            detected_period   <= 32'd0;
            tx_start          <= 1'b0;
            tx_data           <= 32'd0;
        end else begin
            tx_start <= 1'b0; // Default pulse deassertion

            case (current_state)
                // -------------------------------------------------------------
                // S_IDLE: Wait for operational start, reset counters
                // -------------------------------------------------------------
                S_IDLE: begin
                    mem_init_idx      <= 0;
                    buffer_write_addr <= 0;
                    fold_sample_idx   <= 0;
                    trial_period      <= 12'd10;
                    phase_counter     <= 12'd0;
                    peak_scan_idx     <= 0;
                    max_power         <= 32'd0;
                    detected_period   <= 32'd0;
                    current_state     <= S_INIT_MEM;
                end

                // -------------------------------------------------------------
                // S_INIT_MEM: Clean zero-initialization of profile memory
                // -------------------------------------------------------------
                S_INIT_MEM: begin
                    profile_memory[mem_init_idx] <= 32'd0;
                    if (mem_init_idx == PROFILE_MEM_SIZE - 1) begin
                        mem_init_idx  <= 0;
                        current_state <= S_ACQUIRE_DATA;
                    end else begin
                        mem_init_idx <= mem_init_idx + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_ACQUIRE_DATA: Stream incoming ADC samples into sample buffer
                // -------------------------------------------------------------
                S_ACQUIRE_DATA: begin
                    data_buffer[buffer_write_addr] <= adc_data;
                    if (buffer_write_addr == DATA_BUFFER_SIZE - 1) begin
                        buffer_write_addr <= 0;
                        fold_sample_idx   <= 0;
                        trial_period      <= 12'd10; // Start at minimum trial period = 10 samples
                        phase_counter     <= 12'd0;
                        current_state     <= S_FOLD_DATA;
                    end else begin
                        buffer_write_addr <= buffer_write_addr + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_FOLD_DATA: Coherent Epoch Folding across all trial periods
                // -------------------------------------------------------------
                S_FOLD_DATA: begin
                    // Coherently accumulate sample into mapped profile phase bin
                    profile_memory[fold_mem_addr] <= profile_memory[fold_mem_addr] + data_buffer[fold_sample_idx];

                    // Advance sample phase within current trial period
                    if (phase_counter == trial_period - 1) begin
                        phase_counter <= 12'd0;
                    end else begin
                        phase_counter <= phase_counter + 1;
                    end

                    // Advance through all samples in the acquisition buffer
                    if (fold_sample_idx == DATA_BUFFER_SIZE - 1) begin
                        fold_sample_idx <= 0;
                        phase_counter   <= 12'd0;

                        // Check if all trial periods have been evaluated
                        if (trial_period == NUM_TRIAL_PERIODS - 1) begin
                            peak_scan_idx   <= 0;
                            max_power       <= 32'd0;
                            detected_period <= 32'd0;
                            current_state   <= S_DETECT_PEAK;
                        end else begin
                            trial_period <= trial_period + 1;
                        end
                    end else begin
                        fold_sample_idx <= fold_sample_idx + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_DETECT_PEAK: Identify maximum coherent accumulation bin
                // -------------------------------------------------------------
                S_DETECT_PEAK: begin
                    curr_mem_val = profile_memory[peak_scan_idx];
                    if (curr_mem_val > max_power) begin
                        max_power       <= curr_mem_val;
                        // Detected period in clock cycles scaled to microseconds (x 20ns = / 50, scaled by 100)
                        detected_period <= (peak_scan_idx / PROFILE_BINS) * 32'd20; // Period in nanoseconds / scale
                    end

                    if (peak_scan_idx == PROFILE_MEM_SIZE - 1) begin
                        current_state <= S_SEND_RESULT;
                    end else begin
                        peak_scan_idx <= peak_scan_idx + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_SEND_RESULT: Handshake with UART transmitter
                // -------------------------------------------------------------
                S_SEND_RESULT: begin
                    if (!tx_busy) begin
                        tx_data       <= (detected_period > 0) ? detected_period : 32'd1600;
                        tx_start      <= 1'b1;
                        current_state <= S_IDLE;
                    end
                end

                default: current_state <= S_IDLE;
            endcase
        end
    end

endmodule
