// File: ffa_uart_agent.sv
// Description: Passive UVM Agent monitoring the UART serial output
`ifndef FFA_UART_AGENT_SV
`define FFA_UART_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class ffa_uart_agent extends uvm_agent;
    `uvm_component_utils(ffa_uart_agent)

    ffa_uart_monitor monitor;
    uvm_analysis_port #(ffa_uart_item) ap;

    function new(string name = "ffa_uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        monitor = ffa_uart_monitor::type_id::create("monitor", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(this.ap);
    endfunction : connect_phase

endclass : ffa_uart_agent

`endif // FFA_UART_AGENT_SV
