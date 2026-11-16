// File: ffa_pkg.sv
// Description: Master UVM Package for the FPGA Fast Folding Algorithm (FFA) Accelerator
`ifndef FFA_PKG_SV
`define FFA_PKG_SV

`timescale 1ns / 1ps

package ffa_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Types and definitions
    import ffa_types_pkg::*;

    // Transactions
    `include "ffa_adc_item.sv"
    `include "ffa_uart_item.sv"

    // Reference Database & Software Model
    `include "ffa_atnf_catalogue.sv"
    `include "ffa_ref_model.sv"

    // Components & Agents
    `include "ffa_adc_sequencer.sv"
    `include "ffa_adc_driver.sv"
    `include "ffa_adc_monitor.sv"
    `include "ffa_uart_monitor.sv"
    `include "ffa_adc_agent.sv"
    `include "ffa_uart_agent.sv"

    // Verification Analysis
    `include "ffa_scoreboard.sv"
    `include "ffa_coverage.sv"

    // Environment & Sequences
    `include "ffa_env.sv"
    `include "ffa_sequence.sv"

    // Test Library
    `include "tests/ffa_base_test.sv"
    `include "tests/ffa_sanity_test.sv"
    `include "tests/ffa_random_noisy_test.sv"
    `include "tests/ffa_atnf_test.sv"
    `include "tests/ffa_stress_test.sv"
    `include "tests/ffa_master_verification_test.sv"

endpackage : ffa_pkg

`endif // FFA_PKG_SV
