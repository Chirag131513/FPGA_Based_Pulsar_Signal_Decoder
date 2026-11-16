// File: ffa_if.sv
// Description: SystemVerilog Interface for Fast Folding Algorithm (FFA) Accelerator
// Author: Chirag131513
`timescale 1ns / 1ps

interface ffa_if #(
    parameter CLKS_PER_BIT = 5208
)(
    input logic clk
);
    // Asynchronous / synchronous reset
    logic        rst;

    // ADC input stream
    logic [7:0]  adc_data_in;

    // Serial output
    logic        uart_tx_pin;

    // Internal FFA signals (tapped for verification & assertions)
    logic        tx_start;
    logic [31:0] tx_data;
    logic        tx_busy;
    logic [2:0]  ffa_state;
    logic [31:0] buffer_write_addr;
    logic [11:0] trial_period;
    logic [9:0]  fold_bin_addr;
    logic [31:0] max_power;
    logic [31:0] detected_period;

    // =========================================================================
    // Driver Clocking Block (Active Driving)
    // =========================================================================
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output adc_data_in;
        input  rst;
    endclocking

    // =========================================================================
    // ADC Monitor Clocking Block (Passive Sampling)
    // =========================================================================
    clocking adc_mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input adc_data_in;
        input rst;
        input ffa_state;
        input buffer_write_addr;
    endclocking

    // =========================================================================
    // UART Monitor Clocking Block
    // =========================================================================
    clocking uart_mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input uart_tx_pin;
        input tx_start;
        input tx_data;
        input tx_busy;
        input rst;
    endclocking

    // =========================================================================
    // Modports
    // =========================================================================
    modport drv_mp (
        clocking drv_cb,
        output   rst
    );

    modport adc_mon_mp (
        clocking adc_mon_cb
    );

    modport uart_mon_mp (
        clocking uart_mon_cb
    );

endinterface : ffa_if
