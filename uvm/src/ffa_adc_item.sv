// File: ffa_adc_item.sv
// Description: UVM Sequence Item for ADC Time-Series Stimulus with Constrained-Random Noisy Signal Models
`ifndef FFA_ADC_ITEM_SV
`define FFA_ADC_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_adc_item extends uvm_sequence_item;
    `uvm_object_utils(ffa_adc_item)

    // =========================================================================
    // Random Knobs & Constraints
    // =========================================================================
    rand int unsigned         buffer_size;
    rand int unsigned         period_cycles;
    rand int unsigned         pulse_width_cycles;
    rand bit [7:0]            pulse_amplitude;
    rand bit [7:0]            noise_floor;
    rand bit [7:0]            noise_range;
    rand snr_profile_e        snr_mode;
    rand atnf_pulsar_id_e     target_pulsar;
    rand bit                  enable_jitter;
    rand int                  jitter_max_cycles;

    // Generated time-series sample stream
    rand bit [7:0]            samples[];

    // Metadata for tracking and analysis
    real                      effective_snr_db;
    string                    scenario_name;

    // =========================================================================
    // Constraints
    // =========================================================================
    constraint c_buffer_size {
        buffer_size inside {512, 1024, 2048, 4096, 8192, 16384};
        soft buffer_size == 1024;
    }

    constraint c_period_bounds {
        period_cycles inside {[16 : 256]};
        soft period_cycles == 80; // Default test period
    }

    constraint c_pulse_width {
        pulse_width_cycles inside {[2 : 32]};
        pulse_width_cycles < (period_cycles / 4);
        soft pulse_width_cycles == 4;
    }

    constraint c_noise_and_pulse {
        pulse_amplitude inside {[8'h80 : 8'hF0]};
        noise_floor     inside {[8'h08 : 8'h30]};
        noise_range     inside {[8'h04 : 8'h20]};
        (pulse_amplitude + noise_range) < 8'hFF;
    }

    constraint c_jitter {
        enable_jitter == 1'b0;
        jitter_max_cycles inside {[0 : 3]};
    }

    // =========================================================================
    // Constructor
    // =========================================================================
    function new(string name = "ffa_adc_item");
        super.new(name);
    endfunction : new

    // =========================================================================
    // Post-Randomize: Synthesize Realistic Pulsar + Noise Waveform
    // =========================================================================
    function void post_randomize();
        int cycle_in_period;
        int noise_val;
        int sample_val;
        int pulse_val;
        real sig_power = 0.0;
        real noise_power = 0.0;

        samples = new[buffer_size];

        for (int i = 0; i < buffer_size; i++) begin
            cycle_in_period = i % period_cycles;

            // Compute background noise based on SNR mode
            case (snr_mode)
                SNR_CLEAN: begin
                    noise_val = noise_floor;
                end
                SNR_HIGH: begin
                    noise_val = noise_floor + $urandom_range(0, 8);
                end
                SNR_MEDIUM: begin
                    noise_val = noise_floor + $urandom_range(0, 16);
                end
                SNR_LOW: begin
                    noise_val = noise_floor + $urandom_range(0, 32);
                end
                SNR_BURIED: begin
                    noise_val = noise_floor + $urandom_range(0, 64);
                end
                SNR_PURE_NOISE: begin
                    noise_val = noise_floor + $urandom_range(0, 64);
                end
                default: begin
                    noise_val = noise_floor + $urandom_range(0, 16);
                end
            endcase

            // Pulse injection
            if (snr_mode != SNR_PURE_NOISE && cycle_in_period < pulse_width_cycles) begin
                case (snr_mode)
                    SNR_CLEAN:  pulse_val = pulse_amplitude;
                    SNR_HIGH:   pulse_val = pulse_amplitude + $urandom_range(0, 8);
                    SNR_MEDIUM: pulse_val = (pulse_amplitude * 3) / 4 + $urandom_range(0, 12);
                    SNR_LOW:    pulse_val = pulse_amplitude / 2 + $urandom_range(0, 16);
                    SNR_BURIED: pulse_val = pulse_amplitude / 3 + $urandom_range(0, 16);
                    default:    pulse_val = pulse_amplitude;
                endcase
                sample_val = pulse_val + noise_val;
            end else begin
                sample_val = noise_val;
            end

            // Saturate to 8-bit unsigned dynamic range [0, 255]
            if (sample_val > 255) sample_val = 255;
            if (sample_val < 0)   sample_val = 0;

            samples[i] = sample_val[7:0];
        end

        // Estimate SNR in dB
        case (snr_mode)
            SNR_CLEAN:      effective_snr_db = 30.0;
            SNR_HIGH:       effective_snr_db = 15.0;
            SNR_MEDIUM:     effective_snr_db = 6.0;
            SNR_LOW:        effective_snr_db = 0.5;
            SNR_BURIED:     effective_snr_db = -4.0;
            SNR_PURE_NOISE: effective_snr_db = -99.0;
        endcase
    endfunction : post_randomize

    // =========================================================================
    // Format string representation
    // =========================================================================
    virtual function string convert2string();
        return $sformatf("[ADC Item] BufSize=%0d Period=%0d PulWidth=%0d SNR_Mode=%s EstSNR=%.1fdB Target=%s",
                         buffer_size, period_cycles, pulse_width_cycles, snr_mode.name(), effective_snr_db, target_pulsar.name());
    endfunction : convert2string

endclass : ffa_adc_item

`endif // FFA_ADC_ITEM_SV
