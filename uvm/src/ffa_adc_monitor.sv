// File: ffa_adc_monitor.sv
// Description: UVM Monitor observing the ADC input interface and publishing recorded frame items
`ifndef FFA_ADC_MONITOR_SV
`define FFA_ADC_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_adc_monitor extends uvm_monitor;
    `uvm_component_utils(ffa_adc_monitor)

    virtual ffa_if vif;
    uvm_analysis_port #(ffa_adc_item) ap;

    int unsigned data_buffer_size = 1024;

    function new(string name = "ffa_adc_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ffa_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
        void'(uvm_config_db#(int unsigned)::get(this, "", "data_buffer_size", data_buffer_size));
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        ffa_adc_item mon_item;
        bit [7:0] sample_buf[$];

        // Wait until out of reset
        wait(vif.rst === 1'b0);

        forever begin
            sample_buf.delete();

            // Wait until entering S_ACQUIRE_DATA
            wait(vif.adc_mon_cb.ffa_state == FFA_S_ACQUIRE_DATA);

            // Collect samples during acquisition phase
            while (vif.adc_mon_cb.ffa_state == FFA_S_ACQUIRE_DATA) begin
                sample_buf.push_back(vif.adc_mon_cb.adc_data_in);
                @(vif.adc_mon_cb);
            end

            if (sample_buf.size() > 0) begin
                mon_item = ffa_adc_item::type_id::create("mon_item");
                mon_item.buffer_size = sample_buf.size();
                mon_item.samples = new[sample_buf.size()];
                for (int i = 0; i < sample_buf.size(); i++) begin
                    mon_item.samples[i] = sample_buf[i];
                end

                `uvm_info("ADC_MON", $sformatf("Monitored complete ADC buffer (%0d samples)", mon_item.buffer_size), UVM_HIGH)
                ap.write(mon_item);
            end
        end
    endtask : run_phase

endclass : ffa_adc_monitor

`endif // FFA_ADC_MONITOR_SV
