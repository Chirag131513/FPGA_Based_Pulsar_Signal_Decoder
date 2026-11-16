// File: ffa_adc_driver.sv
// Description: UVM Driver for streaming ADC time-series data to the FFA Accelerator
`ifndef FFA_ADC_DRIVER_SV
`define FFA_ADC_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_adc_driver extends uvm_driver #(ffa_adc_item);
    `uvm_component_utils(ffa_adc_driver)

    virtual ffa_if vif;

    function new(string name = "ffa_adc_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ffa_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        ffa_adc_item req;

        // Initialize driver outputs
        vif.drv_cb.adc_data_in <= 8'h00;

        // Wait until reset is released
        wait(vif.rst === 1'b0);
        repeat(5) @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("DRV_START", $sformatf("Driving Stimulus: %s", req.convert2string()), UVM_MEDIUM)
            
            drive_item(req);

            seq_item_port.item_done();
        end
    endtask : run_phase

    task drive_item(ffa_adc_item item);
        // Wait for DUT to be ready in S_IDLE or S_ACQUIRE_DATA
        wait(vif.ffa_state == FFA_S_IDLE || vif.ffa_state == FFA_S_ACQUIRE_DATA);
        @(vif.drv_cb);

        for (int idx = 0; idx < item.samples.size(); idx++) begin
            vif.drv_cb.adc_data_in <= item.samples[idx];
            @(vif.drv_cb);
        end

        // Return to zero baseline
        vif.drv_cb.adc_data_in <= 8'h00;

        `uvm_info("DRV_DONE", $sformatf("Finished driving %0d ADC samples", item.samples.size()), UVM_HIGH)
    endtask : drive_item

endclass : ffa_adc_driver

`endif // FFA_ADC_DRIVER_SV
