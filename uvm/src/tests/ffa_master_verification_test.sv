// File: ffa_master_verification_test.sv
// Description: Master unified UVM Test executing the entire verification suite in a single run:
//              Sanity benchmark, Constrained-Random Noisy models across all SNR regimes,
//              ATNF Pulsar Catalogue cross-referencing, and extreme noise stress tests.
`ifndef FFA_MASTER_VERIFICATION_TEST_SV
`define FFA_MASTER_VERIFICATION_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_master_verification_test extends ffa_base_test;
    `uvm_component_utils(ffa_master_verification_test)

    function new(string name = "ffa_master_verification_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        ffa_master_seq seq;
        phase.raise_objection(this, "Starting ffa_master_verification_test");

        seq = ffa_master_seq::type_id::create("seq");
        `uvm_info("MASTER_TEST", "Launching Unified Master Verification Sequence...", UVM_NONE)
        seq.start(env.adc_agent.sequencer);

        `uvm_info("MASTER_TEST", "All Verification Stages Executed Successfully. Waiting for Pipeline Drain...", UVM_NONE)
        #60_000_000;

        phase.drop_objection(this, "Finished ffa_master_verification_test");
    endtask : run_phase

endclass : ffa_master_verification_test

`endif // FFA_MASTER_VERIFICATION_TEST_SV
