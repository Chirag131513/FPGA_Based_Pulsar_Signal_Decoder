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
        ffa_adc_item item;
        atnf_pulsar_id_e psr_targets[] = '{
            PSR_DOUBLE_J0737_3039A,  // 1.589 s / benchmark mode
            PSR_CRAB_B0531_21,       // 33.39 ms Crab Pulsar
            PSR_VELA_B0833_45,       // 89.33 ms Vela Pulsar
            PSR_B0329_54,            // 714.52 ms Standard Candle
            PSR_B0950_08,            // 253.06 ms Low Dispersion Pulsar
            PSR_B1937_21             // 1.558 ms Millisecond Pulsar
        };

        phase.raise_objection(this, "Starting ffa_master_verification_test");

        `uvm_info("MASTER_TEST", "==================================================================", UVM_NONE)
        `uvm_info("MASTER_TEST", "  STARTING FULL-CHIP FFA ACCELERATOR UVM VERIFICATION ARCHITECTURE ", UVM_NONE)
        `uvm_info("MASTER_TEST", "==================================================================", UVM_NONE)

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
        #40_000_000;

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
            #40_000_000;
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
            #40_000_000;
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
        #40_000_000;

        // 4B: Pure Noise (False-Positive Check)
        item = ffa_adc_item::type_id::create("pure_noise_item");
        start_item(item);
        void'(item.randomize() with {
            buffer_size == 1024;
            snr_mode    == SNR_PURE_NOISE;
        });
        finish_item(item);
        #40_000_000;

        `uvm_info("MASTER_TEST", "All Verification Stages Executed Successfully. Waiting for Pipeline Drain...", UVM_NONE)
        #60_000_000;

        phase.drop_objection(this, "Finished ffa_master_verification_test");
    endtask : run_phase

endclass : ffa_master_verification_test

`endif // FFA_MASTER_VERIFICATION_TEST_SV
