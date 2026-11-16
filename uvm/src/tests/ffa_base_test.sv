// File: ffa_base_test.sv
// Description: Base UVM Test setting up environment, topology reporting, and phase objections
`ifndef FFA_BASE_TEST_SV
`define FFA_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_base_test extends uvm_test;
    `uvm_component_utils(ffa_base_test)

    ffa_env env;

    function new(string name = "ffa_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ffa_env::type_id::create("env", this);
    endfunction : build_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TOPOLOGY", "Displaying UVM Component Topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    task run_phase(uvm_phase phase);
        // Default run_phase sets simulation watchdog timeout
        uvm_top.set_timeout(500_000_000ns, 1);
    endtask : run_phase

endclass : ffa_base_test

`endif // FFA_BASE_TEST_SV
