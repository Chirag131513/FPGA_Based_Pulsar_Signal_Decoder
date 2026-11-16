// File: uart_tx.v
// Description: Synthesizable UART Transmitter with 0xAA Preamble Synchronization
// Author: Chirag131513
// Target: 9600 Baud @ 50 MHz System Clock (5208 Clocks / Bit)
`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 5208
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        tx_start,
    input  wire [31:0] data_in,
    output reg         tx_out = 1'b1,
    output reg         tx_busy = 1'b0
);

    localparam [2:0]
        S_IDLE            = 3'b000,
        S_START_BIT_BYTE  = 3'b001,
        S_DATA_BITS_BYTE  = 3'b010,
        S_STOP_BIT_BYTE   = 3'b011,
        S_START_BIT_DATA  = 3'b100,
        S_DATA_BITS       = 3'b101,
        S_STOP_BIT_DATA   = 3'b110;

    reg [2:0]                      current_state = S_IDLE;
    reg [$clog2(CLKS_PER_BIT)-1:0] clk_counter = 0;
    reg [4:0]                      bit_index = 0;
    reg [7:0]                      byte_reg = 8'h00;
    reg [31:0]                     data_reg = 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            current_state <= S_IDLE;
            tx_out        <= 1'b1;
            tx_busy       <= 1'b0;
            clk_counter   <= 0;
            bit_index     <= 0;
            byte_reg      <= 8'h00;
            data_reg      <= 32'd0;
        end else begin
            case (current_state)
                S_IDLE: begin
                    tx_busy     <= 1'b0;
                    tx_out      <= 1'b1;
                    clk_counter <= 0;
                    bit_index   <= 0;
                    if (tx_start) begin
                        data_reg      <= data_in;
                        byte_reg      <= 8'hAA; // Mandatory 0xAA preamble synchronization byte
                        tx_busy       <= 1'b1;
                        current_state <= S_START_BIT_BYTE;
                    end
                end

                S_START_BIT_BYTE: begin
                    tx_out <= 1'b0; // Preamble Start Bit (logic 0)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter   <= 0;
                        bit_index     <= 0;
                        current_state <= S_DATA_BITS_BYTE;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_DATA_BITS_BYTE: begin
                    tx_out <= byte_reg[bit_index]; // Transmit 0xAA (LSB first)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        if (bit_index == 7) begin
                            current_state <= S_STOP_BIT_BYTE;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_STOP_BIT_BYTE: begin
                    tx_out <= 1'b1; // Preamble Stop Bit (logic 1)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter   <= 0;
                        current_state <= S_START_BIT_DATA;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_START_BIT_DATA: begin
                    tx_out <= 1'b0; // Data Payload Start Bit (logic 0)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter   <= 0;
                        bit_index     <= 0;
                        current_state <= S_DATA_BITS;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_DATA_BITS: begin
                    tx_out <= data_reg[bit_index]; // Transmit 32-bit payload (LSB first)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        if (bit_index == 31) begin
                            current_state <= S_STOP_BIT_DATA;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_STOP_BIT_DATA: begin
                    tx_out <= 1'b1; // Data Payload Stop Bit (logic 1)
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter   <= 0;
                        current_state <= S_IDLE;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                default: current_state <= S_IDLE;
            endcase
        end
    end

endmodule
