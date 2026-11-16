// File: tb_top.sv
// Description: Master Top-Level SystemVerilog UVM 1.2 Testbench module for FFA Accelerator
//              Houses Device Under Test (DUT), Clock/Reset Generation, SVA Bindings,
//              and UVM Execution Entry Point directly inside the UVM environment.
`timescale 1ns / 1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import ffa_types_pkg::*;
    import ffa_pkg::*;

    // =========================================================================
    // Architectural Configuration Parameters
    // =========================================================================
    parameter DATA_BUFFER_SIZE  = 1024;    // Configurable up to 16,384
    parameter PROFILE_BINS      = 64;      // Configurable up to 256
    parameter NUM_TRIAL_PERIODS = 128;     // Configurable up to 2,048
    parameter CLKS_PER_BIT      = 5208;    // 9600 baud @ 50 MHz clock
    parameter CLK_PERIOD_NS     = 20;      // 50 MHz System Clock (20 ns period)

    // =========================================================================
    // Clock & Signal Generation
    // =========================================================================
    logic clk_50mhz;

    initial begin
        clk_50mhz = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk_50mhz = ~clk_50mhz;
    end

    // =========================================================================
    // Interface Instantiation
    // =========================================================================
    ffa_if #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) intf (
        .clk(clk_50mhz)
    );

    // =========================================================================
    // Device Under Test (DUT) Instantiation
    // =========================================================================
    top #(
        .DATA_BUFFER_SIZE (DATA_BUFFER_SIZE),
        .PROFILE_BINS     (PROFILE_BINS),
        .NUM_TRIAL_PERIODS(NUM_TRIAL_PERIODS),
        .CLKS_PER_BIT     (CLKS_PER_BIT)
    ) dut (
        .clk_50mhz   (clk_50mhz),
        .rst         (intf.rst),
        .adc_data_in (intf.adc_data_in),
        .uart_tx_pin (intf.uart_tx_pin)
    );

    // =========================================================================
    // Probing DUT Internal Signals into Interface
    // =========================================================================
    assign intf.tx_start          = dut.tx_start_signal;
    assign intf.tx_data           = dut.tx_data_signal;
    assign intf.tx_busy           = dut.tx_busy_signal;
    assign intf.ffa_state         = dut.ffa_unit.current_state;
    assign intf.buffer_write_addr = dut.ffa_unit.buffer_write_addr;
    assign intf.trial_period      = dut.ffa_unit.trial_period;
    assign intf.fold_bin_addr     = dut.ffa_unit.active_bin;
    assign intf.max_power         = dut.ffa_unit.max_power;
    assign intf.detected_period   = dut.ffa_unit.detected_period;

    // =========================================================================
    // SVA Assertions Monitor Binding
    // =========================================================================
    ffa_sva #(
        .DATA_BUFFER_SIZE (DATA_BUFFER_SIZE),
        .PROFILE_BINS     (PROFILE_BINS),
        .NUM_TRIAL_PERIODS(NUM_TRIAL_PERIODS),
        .CLKS_PER_BIT     (CLKS_PER_BIT)
    ) sva_inst (
        .clk              (clk_50mhz),
        .rst              (intf.rst),
        .adc_data         (intf.adc_data_in),
        .uart_tx_pin      (intf.uart_tx_pin),
        .tx_start         (intf.tx_start),
        .tx_data          (intf.tx_data),
        .tx_busy          (intf.tx_busy),
        .ffa_state        (intf.ffa_state),
        .buffer_write_addr(intf.buffer_write_addr),
        .trial_period     (intf.trial_period),
        .fold_bin_addr    (intf.fold_bin_addr),
        .max_power        (intf.max_power),
        .detected_period  (intf.detected_period)
    );

    // =========================================================================
    // Reset Sequence & UVM Configuration
    // =========================================================================
    initial begin
        `uvm_info("TB_TOP", "Starting FFA Accelerator UVM 1.2 Verification Environment", UVM_NONE)

        // 1. Register virtual interface and parameters in UVM Config DB
        uvm_config_db#(virtual ffa_if)::set(null, "*", "vif", intf);
        uvm_config_db#(int unsigned)::set(null, "*", "data_buffer_size", DATA_BUFFER_SIZE);
        uvm_config_db#(int unsigned)::set(null, "*", "profile_bins", PROFILE_BINS);
        uvm_config_db#(int unsigned)::set(null, "*", "num_trial_periods", NUM_TRIAL_PERIODS);
        uvm_config_db#(int unsigned)::set(null, "*", "clks_per_bit", CLKS_PER_BIT);

        // 2. Setup Waveform Dumps (Cadence SHM and standard VCD)
        `ifdef DUMP_WAVES
            `uvm_info("TB_TOP", "Enabling Waveform Dumps (VCD + Cadence SHM)...", UVM_NONE)
            $dumpfile("ffa_waves.vcd");
            $dumpvars(0, tb_top);
            // pragma coverage off
            $shm_open("waves.shm");
            $shm_probe("AS");
            // pragma coverage on
        `endif

        // 3. Drive Synchronous Reset
        intf.rst = 1'b1;
        intf.adc_data_in = 8'h00;
        repeat(20) @(posedge clk_50mhz);
        @(negedge clk_50mhz);
        intf.rst = 1'b0;
        `uvm_info("TB_TOP", "Deasserted Reset. System operational.", UVM_NONE)

        // 4. Run Selected UVM Test
        run_test();
    end

endmodule : tb_top
