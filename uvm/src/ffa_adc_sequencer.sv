// File: ffa_adc_sequencer.sv
// Description: UVM Sequencer for ADC input transactions
`ifndef FFA_ADC_SEQUENCER_SV
`define FFA_ADC_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class ffa_adc_sequencer extends uvm_sequencer #(ffa_adc_item);
    `uvm_component_utils(ffa_adc_sequencer)

    function new(string name = "ffa_adc_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
endclass : ffa_adc_sequencer

`endif // FFA_ADC_SEQUENCER_SV
