// File: ffa_random_noisy_test.sv
// Description: UVM Test executing constrained-random noisy signal models across SNR regimes
`ifndef FFA_RANDOM_NOISY_TEST_SV
`define FFA_RANDOM_NOISY_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class ffa_random_noisy_test extends ffa_base_test;
    `uvm_component_utils(ffa_random_noisy_test)

    function new(string name = "ffa_random_noisy_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        ffa_random_noisy_seq seq;
        phase.raise_objection(this, "Starting ffa_random_noisy_test");

        seq = ffa_random_noisy_seq::type_id::create("seq");
        `uvm_info("TEST", "Executing Constrained-Random Noisy Signal Test...", UVM_LOW)
        seq.start(env.adc_agent.sequencer);

        // Allow pipeline and UART transmission latency
        #100_000_000;

        phase.drop_objection(this, "Finished ffa_random_noisy_test");
    endtask : run_phase

endclass : ffa_random_noisy_test

`endif // FFA_RANDOM_NOISY_TEST_SV
