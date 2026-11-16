// File: ffa_sva.sv
// Description: Comprehensive SystemVerilog Assertions (SVA) Monitor for FFA Engine & UART Transmitter
// Author: Chirag131513
`timescale 1ns / 1ps

module ffa_sva #(
    parameter DATA_BUFFER_SIZE  = 1024,
    parameter PROFILE_BINS      = 64,
    parameter NUM_TRIAL_PERIODS = 128,
    parameter CLKS_PER_BIT      = 5208
)(
    input logic        clk,
    input logic        rst,
    input logic [7:0]  adc_data,
    input logic        uart_tx_pin,
    input logic        tx_start,
    input logic [31:0] tx_data,
    input logic        tx_busy,
    input logic [2:0]  ffa_state,
    input logic [31:0] buffer_write_addr,
    input logic [11:0] trial_period,
    input logic [9:0]  fold_bin_addr,
    input logic [31:0] max_power,
    input logic [31:0] detected_period
);

    import ffa_types_pkg::*;

    // =========================================================================
    // 1. Reset Assertions
    // =========================================================================
    property p_reset_state;
        @(posedge clk) (rst ##1 rst) |-> (ffa_state == FFA_S_IDLE && tx_start == 1'b0 && buffer_write_addr == 0);
    endproperty
    a_reset_state: assert property (p_reset_state)
        else $error("[SVA-ERROR] Reset condition violation: FSM, tx_start, or buffer addr not reset correctly!");

    property p_uart_idle_after_reset;
        @(posedge clk) disable iff (rst) (!tx_busy && ffa_state == FFA_S_IDLE) |-> (uart_tx_pin == 1'b1);
    endproperty
    a_uart_idle_after_reset: assert property (p_uart_idle_after_reset)
        else $error("[SVA-ERROR] UART TX line dropped low while transmitter is idle!");

    // =========================================================================
    // 2. FSM Legality & Transition Assertions
    // =========================================================================
    property p_fsm_legal_state;
        @(posedge clk) disable iff (rst) (ffa_state <= FFA_S_SEND_RESULT);
    endproperty
    a_fsm_legal_state: assert property (p_fsm_legal_state)
        else $error("[SVA-ERROR] FFA FSM reached illegal state: %0b", ffa_state);

    property p_fsm_idle_to_init;
        @(posedge clk) disable iff (rst)
        (ffa_state == FFA_S_IDLE) |=> (ffa_state == FFA_S_INIT_MEM);
    endproperty
    a_fsm_idle_to_init: assert property (p_fsm_idle_to_init)
        else $error("[SVA-ERROR] FSM failed transition from S_IDLE to S_INIT_MEM");

    property p_fsm_acquire_to_fold;
        @(posedge clk) disable iff (rst)
        (ffa_state == FFA_S_ACQUIRE_DATA && buffer_write_addr == DATA_BUFFER_SIZE - 1) |=>
        (ffa_state == FFA_S_FOLD_DATA);
    endproperty
    a_fsm_acquire_to_fold: assert property (p_fsm_acquire_to_fold)
        else $error("[SVA-ERROR] FSM failed transition from S_ACQUIRE_DATA to S_FOLD_DATA at buffer limit");

    property p_buffer_addr_in_bounds;
        @(posedge clk) disable iff (rst)
        (ffa_state == FFA_S_ACQUIRE_DATA) |-> (buffer_write_addr < DATA_BUFFER_SIZE);
    endproperty
    a_buffer_addr_in_bounds: assert property (p_buffer_addr_in_bounds)
        else $error("[SVA-ERROR] Buffer write address out of bounds: %0d >= %0d", buffer_write_addr, DATA_BUFFER_SIZE);

    property p_send_result_handshake;
        @(posedge clk) disable iff (rst)
        (ffa_state == FFA_S_SEND_RESULT && !tx_busy) |=> (tx_start == 1'b1);
    endproperty
    a_send_result_handshake: assert property (p_send_result_handshake)
        else $error("[SVA-ERROR] S_SEND_RESULT failed to assert tx_start when UART was not busy!");

    property p_tx_start_pulse_width;
        @(posedge clk) disable iff (rst)
        (tx_start == 1'b1) |=> (tx_start == 1'b0);
    endproperty
    a_tx_start_pulse_width: assert property (p_tx_start_pulse_width)
        else $error("[SVA-ERROR] tx_start remained asserted for more than 1 clock cycle!");

    property p_tx_start_triggers_busy;
        @(posedge clk) disable iff (rst)
        (tx_start == 1'b1) |=> (tx_busy == 1'b1);
    endproperty
    a_tx_start_triggers_busy: assert property (p_tx_start_triggers_busy)
        else $error("[SVA-ERROR] tx_busy failed to assert following tx_start trigger!");

    // =========================================================================
    // 3. Functional Coverage Properties
    // =========================================================================
    c_fsm_idle_state:    cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_IDLE);
    c_fsm_init_state:    cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_INIT_MEM);
    c_fsm_acquire_state: cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_ACQUIRE_DATA);
    c_fsm_fold_state:    cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_FOLD_DATA);
    c_fsm_peak_state:    cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_DETECT_PEAK);
    c_fsm_send_state:    cover property (@(posedge clk) disable iff (rst) ffa_state == FFA_S_SEND_RESULT);

    c_tx_transmission:   cover property (@(posedge clk) disable iff (rst) tx_start && !tx_busy);

endmodule : ffa_sva
