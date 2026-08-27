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
 S_START_BIT_BYTE = 3'b001,
 S_DATA_BITS_BYTE = 3'b010,
 S_STOP_BIT_BYTE = 3'b011,
 S_START_BIT_DATA = 3'b100,
 S_DATA_BITS = 3'b101,
 S_STOP_BIT_DATA = 3'b110;
 reg [2:0] current_state;
 reg [$clog2(CLKS_PER_BIT)-1:0] clk_counter;
 reg [4:0] bit_index;
 reg [7:0] byte_reg;
 reg [31:0] data_reg;

 always @(posedge clk) begin
 if (rst) begin
 current_state <= S_IDLE;
 tx_out <= 1'b1;
 tx_busy <= 1'b0;
 clk_counter <= 0;
 bit_index <= 0;
 end else begin
 case (current_state)
 S_IDLE: begin
 tx_busy <= 1'b0;
 tx_out <= 1'b1;
 if (tx_start) begin
 data_reg <= data_in;
 byte_reg <= 8'hAA;  // Start byte for frame sync
 tx_busy <= 1'b1;
 current_state <= S_START_BIT_BYTE;
 end
 end
 S_START_BIT_BYTE: begin
 tx_out <= 1'b0;  // Start bit
 if (clk_counter == CLKS_PER_BIT - 1) begin
   clk_counter <= 0;
   bit_index <= 0;
   current_state <= S_DATA_BITS_BYTE;
 end else begin
   clk_counter <= clk_counter + 1;
 end
 end
 S_DATA_BITS_BYTE: begin
 tx_out <= byte_reg[bit_index];  // LSB first
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
 tx_out <= 1'b1;  // Stop bit
 if (clk_counter == CLKS_PER_BIT - 1) begin
   clk_counter <= 0;
   current_state <= S_START_BIT_DATA;
 end else begin
   clk_counter <= clk_counter + 1;
 end
 end
 S_START_BIT_DATA: begin
 tx_out <= 1'b0;  // Start bit for 32-bit data
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
 current_state <= S_STOP_BIT_DATA;
 end else begin
 bit_index <= bit_index + 1;
 end
 end else begin
 clk_counter <= clk_counter + 1;
 end
 end
 S_STOP_BIT_DATA: begin
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
