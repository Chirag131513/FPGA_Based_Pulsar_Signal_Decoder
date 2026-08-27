// File: top.v
// Description: Top-level structural module.
`timescale 1ns / 1ps

module top (
 input wire clk_50mhz,
 input wire rst,
 input wire [7:0] adc_data_in,
 output wire uart_tx_pin
);
 wire tx_start_signal;
 wire tx_busy_signal;
 wire [31:0] tx_data_signal;

 ffa_engine ffa_unit (
 .clk (clk_50mhz),
 .rst (rst),
 .adc_data (adc_data_in),
 .tx_start (tx_start_signal),
 .tx_data (tx_data_signal),
 .tx_busy (tx_busy_signal)
 );

 uart_tx uart_unit (
 .clk (clk_50mhz),
 .rst (rst),
 .tx_start (tx_start_signal),
 .data_in (tx_data_signal),
 .tx_out (uart_tx_pin),
 .tx_busy (tx_busy_signal)
 );
endmodule
