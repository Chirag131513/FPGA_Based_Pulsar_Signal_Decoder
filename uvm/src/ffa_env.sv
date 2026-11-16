// File: ffa_env.sv
// Description: UVM Environment integrating Agents, Golden Reference Model, Scoreboard, and Coverage
`ifndef FFA_ENV_SV
`define FFA_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_env extends uvm_env;
    `uvm_component_utils(ffa_env)

    ffa_adc_agent  adc_agent;
    ffa_uart_agent uart_agent;
    ffa_ref_model  ref_model;
    ffa_scoreboard scoreboard;
    ffa_coverage   coverage_collector;

    function new(string name = "ffa_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adc_agent          = ffa_adc_agent::type_id::create("adc_agent", this);
        uart_agent         = ffa_uart_agent::type_id::create("uart_agent", this);
        ref_model          = ffa_ref_model::type_id::create("ref_model", this);
        scoreboard         = ffa_scoreboard::type_id::create("scoreboard", this);
        coverage_collector = ffa_coverage::type_id::create("coverage_collector", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect ADC Stimulus to Golden Model & Coverage
        adc_agent.ap.connect(ref_model.in_export);
        adc_agent.ap.connect(coverage_collector.adc_cov_export);

        // Connect Golden Model Output to Scoreboard Expected Export
        ref_model.out_port.connect(scoreboard.exp_export);

        // Connect Monitored UART Frames to Scoreboard Actual Export & Coverage
        uart_agent.ap.connect(scoreboard.act_export);
        uart_agent.ap.connect(coverage_collector.uart_cov_export);

        `uvm_info("ENV_CONNECT", "All UVM analysis ports and exports successfully wired.", UVM_MEDIUM)
    endfunction : connect_phase

endclass : ffa_env

`endif // FFA_ENV_SV
