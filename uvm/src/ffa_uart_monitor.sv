// File: ffa_uart_monitor.sv
// Description: UVM Monitor for deserializing and verifying UART serial transmissions
`ifndef FFA_UART_MONITOR_SV
`define FFA_UART_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_uart_monitor extends uvm_monitor;
    `uvm_component_utils(ffa_uart_monitor)

    virtual ffa_if vif;
    uvm_analysis_port #(ffa_uart_item) ap;

    int unsigned clks_per_bit = 5208; // Configurable (5208 for 9600 baud @ 50MHz)

    function new(string name = "ffa_uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ffa_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
        void'(uvm_config_db#(int unsigned)::get(this, "", "clks_per_bit", clks_per_bit));
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        ffa_uart_item item;
        bit [7:0]  preamble;
        bit [31:0] period_data;
        bit        framing_ok;

        wait(vif.rst === 1'b0);

        forever begin
            // Wait for falling edge indicating Start Bit of Preamble Byte
            @(negedge vif.uart_tx_pin);
            if (vif.rst === 1'b1) continue;

            item = ffa_uart_item::type_id::create("item");
            item.frame_start_time = $time;
            framing_ok = 1'b1;

            `uvm_info("UART_MON", $sformatf("Detected UART Start Bit at %0t ps", $time), UVM_HIGH)

            // 1. Center of Start Bit
            repeat(clks_per_bit / 2) @(vif.uart_mon_cb);
            if (vif.uart_mon_cb.uart_tx_pin !== 1'b0) begin
                `uvm_error("UART_ERR", "Preamble Start Bit verification failed (not logic 0)")
                framing_ok = 1'b0;
            end

            // 2. Sample 8 Data Bits of Preamble (LSB first)
            preamble = 8'h00;
            for (int b = 0; b < 8; b++) begin
                repeat(clks_per_bit) @(vif.uart_mon_cb);
                preamble[b] = vif.uart_mon_cb.uart_tx_pin;
            end

            // 3. Preamble Stop Bit
            repeat(clks_per_bit) @(vif.uart_mon_cb);
            if (vif.uart_mon_cb.uart_tx_pin !== 1'b1) begin
                `uvm_error("UART_ERR", "Preamble Stop Bit verification failed (not logic 1)")
                framing_ok = 1'b0;
            end

            item.preamble_byte  = preamble;
            item.preamble_valid = (preamble == 8'hAA);

            if (!item.preamble_valid) begin
                `uvm_warning("UART_WARN", $sformatf("Received unexpected preamble: 0x%02H (expected 0xAA)", preamble))
            end else begin
                `uvm_info("UART_MON", $sformatf("Preamble 0xAA synchronized successfully"), UVM_HIGH)
            end

            // 4. Sample 32-bit Data Frame: Start Bit
            repeat(clks_per_bit) @(vif.uart_mon_cb);
            if (vif.uart_mon_cb.uart_tx_pin !== 1'b0) begin
                `uvm_error("UART_ERR", "Data Payload Start Bit verification failed (not logic 0)")
                framing_ok = 1'b0;
            end

            // 5. Sample 32 Data Bits (LSB first)
            period_data = 32'd0;
            for (int b = 0; b < 32; b++) begin
                repeat(clks_per_bit) @(vif.uart_mon_cb);
                period_data[b] = vif.uart_mon_cb.uart_tx_pin;
            end

            // 6. Data Frame Stop Bit
            repeat(clks_per_bit) @(vif.uart_mon_cb);
            if (vif.uart_mon_cb.uart_tx_pin !== 1'b1) begin
                `uvm_error("UART_ERR", "Data Payload Stop Bit verification failed (not logic 1)")
                framing_ok = 1'b0;
            end

            item.period_raw    = period_data;
            item.framing_valid = framing_ok;
            item.frame_end_time = $time;
            item.calculate_units();

            `uvm_info("UART_RECV", $sformatf("Decoded UART Packet: %s", item.convert2string()), UVM_LOW)

            // Publish transaction to Scoreboard
            ap.write(item);
        end
    endtask : run_phase

endclass : ffa_uart_monitor

`endif // FFA_UART_MONITOR_SV
