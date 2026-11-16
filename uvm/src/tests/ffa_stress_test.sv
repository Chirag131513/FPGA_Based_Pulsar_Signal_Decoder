// File: ffa_stress_test.sv
// Description: UVM Test for extreme noise, buried SNR, and pure background false-positive checks
`ifndef FFA_STRESS_TEST_SV
`define FFA_STRESS_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class ffa_stress_test extends ffa_base_test;
    `uvm_component_utils(ffa_stress_test)

    function new(string name = "ffa_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        ffa_stress_seq seq;
        phase.raise_objection(this, "Starting ffa_stress_test");

        seq = ffa_stress_seq::type_id::create("seq");
        `uvm_info("TEST", "Executing Stress & Buried SNR Test...", UVM_LOW)
        seq.start(env.adc_agent.sequencer);

        #100_000_000;

        phase.drop_objection(this, "Finished ffa_stress_test");
    endtask : run_phase

endclass : ffa_stress_test

`endif // FFA_STRESS_TEST_SV
