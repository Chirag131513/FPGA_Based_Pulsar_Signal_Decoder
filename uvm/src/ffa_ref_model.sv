// File: ffa_ref_model.sv
// Description: Software Golden Reference Model simulating the FFA folding and peak detection arithmetic
// Author: Chirag131513
`ifndef FFA_REF_MODEL_SV
`define FFA_REF_MODEL_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_ref_model extends uvm_component;
    `uvm_component_utils(ffa_ref_model)

    uvm_analysis_imp #(ffa_adc_item, ffa_ref_model) in_export;
    uvm_analysis_port #(ffa_uart_item)              out_port;

    int unsigned data_buffer_size  = 1024;
    int unsigned profile_bins      = 64;
    int unsigned num_trial_periods = 128;
    int unsigned profile_mem_size;

    function new(string name = "ffa_ref_model", uvm_component parent = null);
        super.new(name, parent);
        in_export = new("in_export", this);
        out_port  = new("out_port", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(int unsigned)::get(this, "", "data_buffer_size", data_buffer_size));
        void'(uvm_config_db#(int unsigned)::get(this, "", "profile_bins", profile_bins));
        void'(uvm_config_db#(int unsigned)::get(this, "", "num_trial_periods", num_trial_periods));
        profile_mem_size = num_trial_periods * profile_bins;
    endfunction : build_phase

    virtual function void write(ffa_adc_item item);
        ffa_uart_item exp_item;
        bit [31:0] profile_memory[];
        bit [31:0] max_power = 32'd0;
        bit [31:0] detected_period = 32'd0;
        int active_bin;
        int mem_idx;
        int phase_cnt;

        profile_memory = new[profile_mem_size];
        for (int k = 0; k < profile_mem_size; k++) begin
            profile_memory[k] = 32'd0;
        end

        // 1. Emulate Hardware Coherent Epoch Folding Loop
        for (int p = 10; p < num_trial_periods; p++) begin
            phase_cnt = 0;
            for (int s = 0; s < item.samples.size(); s++) begin
                active_bin = (phase_cnt < profile_bins) ? phase_cnt : (phase_cnt % profile_bins);
                mem_idx = p * profile_bins + active_bin;
                profile_memory[mem_idx] = profile_memory[mem_idx] + item.samples[s];

                if (phase_cnt == p - 1) begin
                    phase_cnt = 0;
                end else begin
                    phase_cnt++;
                end
            end
        end

        // 2. Emulate Hardware Peak Detection Loop
        for (int i = 0; i < profile_mem_size; i++) begin
            if (profile_memory[i] > max_power) begin
                max_power       = profile_memory[i];
                detected_period = (i / profile_bins) * 32'd20; // Scaled to period
            end
        end

        if (detected_period == 0) begin
            detected_period = 32'd1600;
        end

        // 3. Assemble Golden Expected Output
        exp_item = ffa_uart_item::type_id::create("exp_item");
        exp_item.preamble_byte  = 8'hAA;
        exp_item.preamble_valid = 1'b1;
        exp_item.period_raw     = detected_period;
        exp_item.framing_valid  = 1'b1;
        exp_item.calculate_units();

        `uvm_info("REF_MODEL", $sformatf("Golden Model Computed: Period=%0d (MaxPower=%0d)", detected_period, max_power), UVM_HIGH)

        out_port.write(exp_item);
    endfunction : write

endclass : ffa_ref_model

`endif // FFA_REF_MODEL_SV
