// File: ffa_coverage.sv
// Description: Comprehensive Functional Coverage Model for FFA Accelerator UVM Environment
// Author: Chirag131513
`ifndef FFA_COVERAGE_SV
`define FFA_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

`uvm_analysis_imp_decl(_cov_adc)
`uvm_analysis_imp_decl(_cov_uart)

class ffa_coverage extends uvm_subscriber #(ffa_adc_item);
    `uvm_component_utils(ffa_coverage)

    uvm_analysis_imp_cov_adc  #(ffa_adc_item, ffa_coverage)  adc_cov_export;
    uvm_analysis_imp_cov_uart #(ffa_uart_item, ffa_coverage) uart_cov_export;

    ffa_adc_item  current_adc_item;
    ffa_uart_item current_uart_item;

    // =========================================================================
    // Covergroup 1: ADC Stimulus & Astrophysical Pulsar Parameters
    // =========================================================================
    covergroup cg_adc_stimulus;
        option.per_instance = 1;
        option.name = "cg_adc_stimulus";

        cp_buffer_size: coverpoint current_adc_item.buffer_size {
            bins buf_512   = {512};
            bins buf_1k    = {1024};
            bins buf_2k    = {2048};
            bins buf_4k    = {4096};
            bins buf_8k    = {8192};
            bins buf_16k   = {16384};
        }

        cp_period: coverpoint current_adc_item.period_cycles {
            bins period_short  = {[16 : 48]};
            bins period_mid    = {[49 : 96]};
            bins period_long   = {[97 : 160]};
            bins period_max    = {[161 : 256]};
        }

        cp_pulse_width: coverpoint current_adc_item.pulse_width_cycles {
            bins width_narrow  = {[2 : 4]};
            bins width_medium  = {[5 : 10]};
            bins width_wide    = {[11 : 32]};
        }

        cp_snr_mode: coverpoint current_adc_item.snr_mode {
            bins clean       = {SNR_CLEAN};
            bins high_snr    = {SNR_HIGH};
            bins med_snr     = {SNR_MEDIUM};
            bins low_snr     = {SNR_LOW};
            bins buried_snr  = {SNR_BURIED};
            bins pure_noise  = {SNR_PURE_NOISE};
        }

        cp_target_pulsar: coverpoint current_adc_item.target_pulsar {
            bins crab        = {PSR_CRAB_B0531_21};
            bins vela        = {PSR_VELA_B0833_45};
            bins double_psr  = {PSR_DOUBLE_J0737_3039A};
            bins b0329       = {PSR_B0329_54};
            bins b0950       = {PSR_B0950_08};
            bins b1937_msp   = {PSR_B1937_21};
            bins j0437       = {PSR_J0437_4715};
            bins bell_1919   = {PSR_BELL_B1919_21};
            bins benchmark   = {PSR_TEST_BENCHMARK};
        }

        cross_snr_x_period: cross cp_snr_mode, cp_period;
    endgroup : cg_adc_stimulus

    // =========================================================================
    // Covergroup 2: UART Serial Frame & Detected Period
    // =========================================================================
    covergroup cg_uart_response;
        option.per_instance = 1;
        option.name = "cg_uart_response";

        cp_preamble: coverpoint current_uart_item.preamble_byte {
            bins sync_0xaa = {8'hAA};
            bins invalid   = default;
        }

        cp_framing_valid: coverpoint current_uart_item.framing_valid {
            bins valid   = {1'b1};
            bins invalid = {1'b0};
        }

        cp_detected_period: coverpoint current_uart_item.period_raw {
            bins short_period = {[1000 : 5000]};
            bins mid_period   = {[5001 : 20000]};
            bins long_period  = {[20001 : 100000]};
            bins max_period   = {[100001 : 5000000]};
        }
    endgroup : cg_uart_response

    function new(string name = "ffa_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_adc_stimulus  = new();
        cg_uart_response = new();
        adc_cov_export   = new("adc_cov_export", this);
        uart_cov_export  = new("uart_cov_export", this);
    endfunction : new

    virtual function void write(ffa_adc_item t);
        write_cov_adc(t);
    endfunction : write

    virtual function void write_cov_adc(ffa_adc_item item);
        current_adc_item = item;
        cg_adc_stimulus.sample();
    endfunction : write_cov_adc

    virtual function void write_cov_uart(ffa_uart_item item);
        current_uart_item = item;
        cg_uart_response.sample();
    endfunction : write_cov_uart

endclass : ffa_coverage

`endif // FFA_COVERAGE_SV
