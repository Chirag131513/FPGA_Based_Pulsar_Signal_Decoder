// File: top.v
// Description: Top-level structural module with parameter pass-through.
`timescale 1ns / 1ps

module top #(
    parameter DATA_BUFFER_SIZE  = 1024,
    parameter PROFILE_BINS      = 64,
    parameter NUM_TRIAL_PERIODS = 128,
    parameter CLKS_PER_BIT      = 5208
)(
    input  wire        clk_50mhz,
    input  wire        rst,
    input  wire [7:0]  adc_data_in,
    output wire        uart_tx_pin
);
    wire tx_start_signal;
    wire tx_busy_signal;
    wire [31:0] tx_data_signal;

    ffa_engine #(
        .DATA_BUFFER_SIZE(DATA_BUFFER_SIZE),
        .PROFILE_BINS(PROFILE_BINS),
        .NUM_TRIAL_PERIODS(NUM_TRIAL_PERIODS)
    ) ffa_unit (
        .clk(clk_50mhz),
        .rst(rst),
        .adc_data(adc_data_in),
        .tx_start(tx_start_signal),
        .tx_data(tx_data_signal),
        .tx_busy(tx_busy_signal)
    );

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_unit (
        .clk(clk_50mhz),
        .rst(rst),
        .tx_start(tx_start_signal),
        .data_in(tx_data_signal),
        .tx_out(uart_tx_pin),
        .tx_busy(tx_busy_signal)
    );

endmodule
