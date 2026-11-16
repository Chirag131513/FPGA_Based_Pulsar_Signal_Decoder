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

// =============================================================================
// Master Unified Verification Sequence
// =============================================================================
class ffa_master_seq extends ffa_base_seq;
    `uvm_object_utils(ffa_master_seq)

    function new(string name = "ffa_master_seq");
        super.new(name);
    endfunction : new

    task body();
        ffa_adc_item item;
        atnf_pulsar_id_e psr_targets[] = '{
            PSR_DOUBLE_J0737_3039A,  // 1.589 s / benchmark mode
            PSR_CRAB_B0531_21,       // 33.39 ms Crab Pulsar
            PSR_VELA_B0833_45,       // 89.33 ms Vela Pulsar
            PSR_B0329_54,            // 714.52 ms Standard Candle
            PSR_B0950_08,            // 253.06 ms Low Dispersion Pulsar
            PSR_B1937_21             // 1.558 ms Millisecond Pulsar
        };

        `uvm_info("MASTER_SEQ", "==================================================================", UVM_NONE)
        `uvm_info("MASTER_SEQ", "  STARTING FULL-CHIP FFA ACCELERATOR UVM VERIFICATION ARCHITECTURE ", UVM_NONE)
        `uvm_info("MASTER_SEQ", "==================================================================", UVM_NONE)

        // ---------------------------------------------------------------------
        // STAGE 1: Sanity Benchmark Verification (1600 us)
        // ---------------------------------------------------------------------
        `uvm_info("STAGE_1", ">>> [STAGE 1/4] Running Deterministic Benchmark Sanity Test...", UVM_NONE)
        item = ffa_adc_item::type_id::create("sanity_item");
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
        #12_000_000;

        // ---------------------------------------------------------------------
        // STAGE 2: ATNF Pulsar Database Signature Injection & Cross-Referencing
        // ---------------------------------------------------------------------
        `uvm_info("STAGE_2", ">>> [STAGE 2/4] Injecting Real ATNF Pulsar Signatures for Database Matching...", UVM_NONE)
        foreach (psr_targets[idx]) begin
            item = ffa_adc_item::type_id::create($sformatf("atnf_item_%0d", idx));
            start_item(item);
            if (!item.randomize() with {
                buffer_size   == 1024;
                target_pulsar == psr_targets[idx];
                snr_mode inside {SNR_HIGH, SNR_MEDIUM};
            }) begin
                `uvm_fatal("RND_FAIL", "ATNF item randomization failed!")
            end
            `uvm_info("ATNF_INJECT", $sformatf("Injected Target: %s (Period: %0d cycles)", 
                      psr_targets[idx].name(), item.period_cycles), UVM_LOW)
            finish_item(item);
            #12_000_000;
        end

        // ---------------------------------------------------------------------
        // STAGE 3: Constrained-Random Noisy Signal Models Across All SNR Regimes
        // ---------------------------------------------------------------------
        `uvm_info("STAGE_3", ">>> [STAGE 3/4] Sweeping Constrained-Random Noisy Models (Clean, Med, Low, Buried)...", UVM_NONE)
        for (int snr_idx = 0; snr_idx < 4; snr_idx++) begin
            item = ffa_adc_item::type_id::create($sformatf("noisy_item_%0d", snr_idx));
            start_item(item);
            if (!item.randomize() with {
                buffer_size inside {1024, 2048};
                period_cycles inside {[32 : 128]};
                snr_mode == snr_profile_e'(snr_idx); // Sweeps CLEAN -> HIGH -> MEDIUM -> LOW
            }) begin
                `uvm_fatal("RND_FAIL", "Noisy sweep randomization failed!")
            end
            `uvm_info("NOISE_SWEEP", $sformatf("Injected: %s", item.convert2string()), UVM_LOW)
            finish_item(item);
            #12_000_000;
        end

        // ---------------------------------------------------------------------
        // STAGE 4: Stress Testing (Buried Sub-Zero SNR & Pure Noise Rejection)
        // ---------------------------------------------------------------------
        `uvm_info("STAGE_4", ">>> [STAGE 4/4] Executing Stress & Buried SNR Verification...", UVM_NONE)
        
        // 4A: Buried in heavy noise (SNR < 0 dB)
        item = ffa_adc_item::type_id::create("buried_item");
        start_item(item);
        void'(item.randomize() with {
            buffer_size     == 1024;
            snr_mode        == SNR_BURIED;
            pulse_amplitude == 8'h30;
            noise_floor     == 8'h20;
            noise_range     == 8'h40;
        });
        finish_item(item);
        #12_000_000;

        // 4B: Pure Noise (False-Positive Check)
        item = ffa_adc_item::type_id::create("pure_noise_item");
        start_item(item);
        void'(item.randomize() with {
            buffer_size == 1024;
            snr_mode    == SNR_PURE_NOISE;
        });
        finish_item(item);
        #12_000_000;

        `uvm_info("MASTER_SEQ", "All Verification Sequence Stimulus Completed.", UVM_NONE)
    endtask : body
endclass : ffa_master_seq

`endif // FFA_SEQUENCE_SV
