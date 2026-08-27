// File: uart_tx.v
// Description: UART Transmitter module with start byte framing.
`timescale 1ns / 1ps

module uart_tx #(
 parameter CLKS_PER_BIT = 5208 // For 9600 baud @ 50 MHz clock
)(
 input wire clk,
 input wire rst,
 input wire tx_start,
 input wire [31:0] data_in,
 output reg tx_out = 1'b1,
 output reg tx_busy
);
 localparam [2:0]
 S_IDLE = 3'b000,
 S_START_BYTE = 3'b001,
 S_START_BIT = 3'b010,
 S_DATA_BITS = 3'b011,
 S_STOP_BIT = 3'b100;
 reg [2:0] current_state;
 reg [$clog2(CLKS_PER_BIT)-1:0] clk_counter;
 reg [4:0] bit_index;
 reg [31:0] data_reg;
 reg send_start_byte;

 always @(posedge clk) begin
 if (rst) begin
 current_state <= S_IDLE;
 tx_out <= 1'b1;
 tx_busy <= 1'b0;
 clk_counter <= 0;
 bit_index <= 0;
 send_start_byte <= 1'b0;
 end else begin
 case (current_state)
 S_IDLE: begin
 tx_busy <= 1'b0;
 tx_out <= 1'b1;
 send_start_byte <= 1'b0;
 if (tx_start) begin
 data_reg <= data_in;
 tx_busy <= 1'b1;
 send_start_byte <= 1'b1;
 current_state <= S_START_BYTE;
 end
 end
 S_START_BYTE: begin
 // Send start byte 0xAA for frame synchronization
 tx_out <= 1'b0; // Start bit for 0xAA
 if (clk_counter == CLKS_PER_BIT - 1) begin
 clk_counter <= 0;
 bit_index <= 0;
 current_state <= S_START_BIT;
 end else begin
 clk_counter <= clk_counter + 1;
 end
 end
 S_START_BIT: begin
 tx_out <= 1'b0;
 if (clk_counter == CLKS_PER_BIT - 1) begin
 clk_counter <= 0;
 bit_index <= 0;
 current_state <= S_DATA_BITS;
 end else begin
 clk_counter <= clk_counter + 1;
 end
 end
 S_DATA_BITS: begin
 tx_out <= data_reg[bit_index];
 if (clk_counter == CLKS_PER_BIT - 1) begin
 clk_counter <= 0;
 if (bit_index == 31) begin
 current_state <= S_STOP_BIT;
 end else begin
 bit_index <= bit_index + 1;
 end
 end else begin
 clk_counter <= clk_counter + 1;
 end
 end
 S_STOP_BIT: begin
 tx_out <= 1'b1;
 if (clk_counter == CLKS_PER_BIT - 1) begin
 clk_counter <= 0;
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
