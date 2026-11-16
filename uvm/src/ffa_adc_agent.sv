// File: ffa_adc_agent.sv
// Description: Active UVM Agent encapsulating sequencer, driver, and monitor for the ADC interface
`ifndef FFA_ADC_AGENT_SV
`define FFA_ADC_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class ffa_adc_agent extends uvm_agent;
    `uvm_component_utils(ffa_adc_agent)

    ffa_adc_sequencer sequencer;
    ffa_adc_driver    driver;
    ffa_adc_monitor   monitor;
    uvm_analysis_port #(ffa_adc_item) ap;

    function new(string name = "ffa_adc_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        monitor = ffa_adc_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = ffa_adc_sequencer::type_id::create("sequencer", this);
            driver    = ffa_adc_driver::type_id::create("driver", this);
        end
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(this.ap);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction : connect_phase

endclass : ffa_adc_agent

`endif // FFA_ADC_AGENT_SV
