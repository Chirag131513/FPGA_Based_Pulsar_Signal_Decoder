// File: ffa_sequence.sv
// Description: UVM Sequences including Sanity, Constrained-Random Noisy Models, and ATNF Signature Injections
// Author: Chirag131513
`ifndef FFA_SEQUENCE_SV
`define FFA_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

// =============================================================================
// Base Sequence
// =============================================================================
class ffa_base_seq extends uvm_sequence #(ffa_adc_item);
    `uvm_object_utils(ffa_base_seq)

    function new(string name = "ffa_base_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("BASE_SEQ", "Executing Base Sequence...", UVM_MEDIUM)
    endtask : body
endclass : ffa_base_seq

// =============================================================================
// Sanity Sequence (Deterministic Verification Benchmark)
// =============================================================================
class ffa_sanity_seq extends ffa_base_seq;
    `uvm_object_utils(ffa_sanity_seq)

    function new(string name = "ffa_sanity_seq");
        super.new(name);
    endfunction : new

    task body();
        ffa_adc_item item;
        item = ffa_adc_item::type_id::create("item");

        `uvm_info("SANITY_SEQ", "Starting Sanity Sequence with standard benchmark period (1600 us)...", UVM_LOW)

        start_item(item);
        if (!item.randomize() with {
            buffer_size        == 1024;
            period_cycles      == 80;
            pulse_width_cycles == 4;
            snr_mode           == SNR_HIGH;
            pulse_amplitude    == 8'hA0;
            noise_floor        == 8'h10;
            target_pulsar      == PSR_DOUBLE_J0737_3039A;
        }) begin
            `uvm_fatal("RND_FAIL", "Sanity item randomization failed!")
        end
        finish_item(item);

        `uvm_info("SANITY_SEQ", "Sanity Sequence stimulus completed.", UVM_LOW)
    endtask : body
endclass : ffa_sanity_seq

// =============================================================================
// Constrained-Random Noisy Signal Sequence
// =============================================================================
class ffa_random_noisy_seq extends ffa_base_seq;
    `uvm_object_utils(ffa_random_noisy_seq)

    rand int num_iterations;
    constraint c_iter { num_iterations inside {[3 : 6]}; }

    function new(string name = "ffa_random_noisy_seq");
        super.new(name);
    endfunction : new

    task body();
        ffa_adc_item item;
        `uvm_info("NOISY_SEQ", $sformatf("Launching Constrained-Random Noisy Signal Sequence (%0d iterations)", num_iterations), UVM_LOW)

        for (int i = 0; i < num_iterations; i++) begin
            item = ffa_adc_item::type_id::create($sformatf("noisy_item_%0d", i));
            start_item(item);

            if (!item.randomize() with {
                buffer_size inside {1024, 2048};
                period_cycles inside {[24 : 120]};
                snr_mode inside {SNR_HIGH, SNR_MEDIUM, SNR_LOW, SNR_BURIED};
            }) begin
                `uvm_fatal("RND_FAIL", "Constrained-random item generation failed!")
            end

            `uvm_info("NOISY_SEQ", $sformatf("Iter %0d: Injected %s", i, item.convert2string()), UVM_MEDIUM)
            finish_item(item);

            #50_000_000;
        end
    endtask : body
endclass : ffa_random_noisy_seq

// =============================================================================
// ATNF Pulsar Injection Sequence
// =============================================================================
class ffa_atnf_pulsar_seq extends ffa_base_seq;
    `uvm_object_utils(ffa_atnf_pulsar_seq)

    function new(string name = "ffa_atnf_pulsar_seq");
        super.new(name);
    endfunction : new

    task body();
        ffa_adc_item item;
        atnf_pulsar_id_e psr_list[] = '{
            PSR_DOUBLE_J0737_3039A,
            PSR_CRAB_B0531_21,
            PSR_VELA_B0833_45,
            PSR_B0329_54
        };

        `uvm_info("ATNF_SEQ", "Injecting known ATNF Astrophysical Pulsar Signatures...", UVM_LOW)

        foreach (psr_list[idx]) begin
            item = ffa_adc_item::type_id::create($sformatf("atnf_item_%0d", idx));
            start_item(item);

            if (!item.randomize() with {
                buffer_size   == 1024;
                target_pulsar == psr_list[idx];
                snr_mode inside {SNR_HIGH, SNR_MEDIUM};
            }) begin
                `uvm_fatal("RND_FAIL", "ATNF sequence item randomization failed!")
            end

            `uvm_info("ATNF_SEQ", $sformatf("Injected ATNF Pulsar Target: %s", psr_list[idx].name()), UVM_MEDIUM)
            finish_item(item);

            #50_000_000;
        end
    endtask : body
endclass : ffa_atnf_pulsar_seq

// =============================================================================
// Stress & Low-SNR Sequence
// =============================================================================
class ffa_stress_seq extends ffa_base_seq;
    `uvm_object_utils(ffa_stress_seq)

    function new(string name = "ffa_stress_seq");
        super.new(name);
    endfunction : new

    task body();
        ffa_adc_item item;
        `uvm_info("STRESS_SEQ", "Executing Stress & Extreme Noise Verification...", UVM_LOW)

        // Case 1: Buried in noise
        item = ffa_adc_item::type_id::create("buried_noise_item");
        start_item(item);
        void'(item.randomize() with {
            buffer_size     == 1024;
            snr_mode        == SNR_BURIED;
            pulse_amplitude == 8'h30;
            noise_floor     == 8'h20;
            noise_range     == 8'h40;
        });
        finish_item(item);
        #50_000_000;

        // Case 2: Pure noise (False positive test)
        item = ffa_adc_item::type_id::create("pure_noise_item");
        start_item(item);
        void'(item.randomize() with {
            buffer_size == 1024;
            snr_mode    == SNR_PURE_NOISE;
        });
        finish_item(item);
        #50_000_000;
    endtask : body
endclass : ffa_stress_seq

`endif // FFA_SEQUENCE_SV
