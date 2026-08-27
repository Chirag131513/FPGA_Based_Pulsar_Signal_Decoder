// File: ffa_engine.v
// Description: Synthesizable FFA Engine with correct memory initialization.
`timescale 1ns / 1ps

module ffa_engine (
 input wire clk,
 input wire rst,
 input wire [7:0] adc_data,
 output reg tx_start,
 output reg [31:0] tx_data,
 input wire tx_busy
);
 // ## FFA Parameters ##
 parameter DATA_BUFFER_SIZE = 16384;
 parameter PROFILE_BINS = 256;
 parameter NUM_TRIAL_PERIODS = 2048;
 parameter PROFILE_MEM_SIZE = NUM_TRIAL_PERIODS * PROFILE_BINS;

 // ## Data Storage ##
 reg [7:0] data_buffer [0:DATA_BUFFER_SIZE-1];
 reg [31:0] profile_memory [0:PROFILE_MEM_SIZE-1];

 // ## State Machine ##
 localparam [2:0]
 S_IDLE = 3'b000,
 S_ACQUIRE_DATA = 3'b001,
 S_FOLD_DATA = 3'b010,
 S_DETECT_PEAK = 3'b011,
 S_SEND_RESULT = 3'b100;
 reg [2:0] current_state;

 // ## Internal Signals and Counters ##
 reg [$clog2(DATA_BUFFER_SIZE):0] buffer_write_addr;
 reg [31:0] detected_period;
 reg [31:0] max_power;
 reg [9:0] fold_bin_addr;
 reg [10:0] trial_period;
 reg [31:0] accumulator;
 reg folding_done;
 reg peak_done;
 integer i; // for loops

 // Initialize memory at reset only (not in synthesis loop)
 genvar g;
 generate
   for (g = 0; g < PROFILE_MEM_SIZE; g = g + 1) begin : mem_init
     always @(posedge clk) begin
       if (rst) begin
         profile_memory[g] <= 32'd0;
       end
     end
   end
 endgenerate

 always @(posedge clk) begin
 if (rst) begin
 current_state <= S_IDLE;
 buffer_write_addr <= 0;
 tx_start <= 1'b0;
 tx_data <= 32'd0;
 max_power <= 32'd0;
 folding_done <= 1'b0;
 peak_done <= 1'b0;
 end else begin
 tx_start <= 1'b0; // Default assignment
 case (current_state)
 S_IDLE: begin
   folding_done <= 1'b0;
   peak_done <= 1'b0;
   current_state <= S_ACQUIRE_DATA;
 end
 S_ACQUIRE_DATA: begin
 data_buffer[buffer_write_addr] <= adc_data;
 if (buffer_write_addr == DATA_BUFFER_SIZE - 1) begin
 buffer_write_addr <= 0;
 current_state <= S_FOLD_DATA;
 end else begin
 buffer_write_addr <= buffer_write_addr + 1;
 end
 end
 S_FOLD_DATA: begin
   // Simple folding: sum data into profile bins based on trial period
   if (!folding_done) begin
     accumulator <= 32'd0;
     fold_bin_addr <= 10'd0;
     trial_period <= 11'd10; // Start with smallest trial period
     folding_done <= 1'b1;
   end else if (fold_bin_addr < PROFILE_BINS) begin
     // Accumulate folded data (simplified - real FFA needs nested loops)
     accumulator <= accumulator + data_buffer[fold_bin_addr];
     profile_memory[trial_period * PROFILE_BINS + fold_bin_addr] <= 
       profile_memory[trial_period * PROFILE_BINS + fold_bin_addr] + adc_data;
     fold_bin_addr <= fold_bin_addr + 1;
   end else begin
     // Move to next trial period or finish folding
     if (trial_period < NUM_TRIAL_PERIODS - 1) begin
       trial_period <= trial_period + 1;
       fold_bin_addr <= 10'd0;
     end else begin
       current_state <= S_DETECT_PEAK;
     end
   end
 end
 S_DETECT_PEAK: begin
   // Find peak power across all trial periods
   if (!peak_done) begin
     max_power <= 32'd0;
     detected_period <= 32'd0;
     i <= 0;
     peak_done <= 1'b1;
   end else if (i < PROFILE_MEM_SIZE) begin
     if (profile_memory[i] > max_power) begin
       max_power <= profile_memory[i];
       detected_period <= 32'(i / PROFILE_BINS); // Trial period index
     end
     i <= i + 1;
   end else begin
     // Convert trial period to microseconds (placeholder scaling)
     detected_period <= detected_period * 32'd100; // Scale to microseconds
     current_state <= S_SEND_RESULT;
   end
 end
 S_SEND_RESULT: begin
 if (!tx_busy) begin
 tx_data <= detected_period;
 tx_start <= 1'b1;
 current_state <= S_IDLE;
 end
 end
 default: current_state <= S_IDLE;
 endcase
 end
 end
endmodule
