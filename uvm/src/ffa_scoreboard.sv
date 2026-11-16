// File: ffa_scoreboard.sv
// Description: UVM Scoreboard with bit-exact prediction comparison and ATNF catalogue cross-referencing
`ifndef FFA_SCOREBOARD_SV
`define FFA_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class ffa_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ffa_scoreboard)

    uvm_analysis_imp_expected #(ffa_uart_item, ffa_scoreboard) exp_export;
    uvm_analysis_imp_actual   #(ffa_uart_item, ffa_scoreboard) act_export;

    ffa_atnf_catalogue atnf_db;

    // Queues for expected and actual transactions
    ffa_uart_item exp_queue[$];
    ffa_uart_item act_queue[$];

    // Verification statistics counters
    int unsigned total_frames_received   = 0;
    int unsigned bit_exact_matches       = 0;
    int unsigned period_mismatches       = 0;
    int unsigned preamble_errors         = 0;
    int unsigned framing_errors          = 0;
    int unsigned atnf_matches_found      = 0;

    function new(string name = "ffa_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        exp_export = new("exp_export", this);
        act_export = new("act_export", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        atnf_db = ffa_atnf_catalogue::type_id::create("atnf_db");
    endfunction : build_phase

    // Analysis write from Golden Reference Model
    virtual function void write_expected(ffa_uart_item item);
        exp_queue.push_back(item);
        `uvm_info("SCB_EXP", $sformatf("Queued Expected Item: %s", item.convert2string()), UVM_HIGH)
        check_transactions();
    endfunction : write_expected

    // Analysis write from UART Monitor
    virtual function void write_actual(ffa_uart_item item);
        act_queue.push_back(item);
        total_frames_received++;
        `uvm_info("SCB_ACT", $sformatf("Queued Actual Item: %s", item.convert2string()), UVM_MEDIUM)
        check_transactions();
    endfunction : write_actual

    // Compare and cross-reference transactions
    virtual function void check_transactions();
        ffa_uart_item exp_item;
        ffa_uart_item act_item;
        int num_atnf_matches;

        while (exp_queue.size() > 0 && act_queue.size() > 0) begin
            exp_item = exp_queue.pop_front();
            act_item = act_queue.pop_front();

            // 1. Verify Preamble
            if (!act_item.preamble_valid || act_item.preamble_byte !== 8'hAA) begin
                preamble_errors++;
                `uvm_error("SCB_PREAMBLE_FAIL",
                    $sformatf("Preamble mismatch! Expected: 0xAA, Actual: 0x%02H", act_item.preamble_byte))
            end

            // 2. Verify Framing
            if (!act_item.framing_valid) begin
                framing_errors++;
                `uvm_error("SCB_FRAMING_FAIL", "UART Framing error detected in transmitted frame!")
            end

            // 3. Compare Hardware Detected Period against Golden Reference Model
            if (act_item.period_raw === exp_item.period_raw) begin
                bit_exact_matches++;
                `uvm_info("SCB_MATCH_EXACT",
                    $sformatf("[PASS] Bit-Exact Match! Period: %0d us (Hardware = Golden = %0d)",
                              act_item.period_raw, exp_item.period_raw), UVM_NONE)
            end else begin
                period_mismatches++;
                `uvm_error("SCB_PERIOD_MISMATCH",
                    $sformatf("[FAIL] Period Mismatch! Actual Hardware: %0d, Golden Expected: %0d",
                              act_item.period_raw, exp_item.period_raw))
            end

            // 4. Cross-Reference against ATNF Catalogue
            num_atnf_matches = atnf_db.query_catalogue(act_item.period_s, 5.0);
            if (num_atnf_matches > 0) begin
                atnf_matches_found += num_atnf_matches;
                `uvm_info("SCB_ATNF_MATCH",
                    $sformatf(">>> [ATNF-SUCCESS] Cross-referenced detected period (%.6f s) with ATNF catalogue: Found %0d match(es):",
                              act_item.period_s, num_atnf_matches), UVM_NONE)
                for (int m = 0; m < num_atnf_matches; m++) begin
                    `uvm_info("SCB_ATNF_DETAIL",
                        $sformatf("    -> %s (%s) | P0 = %.6f s | DM = %.2f pc/cm^3",
                                  atnf_db.matched_pulsars[m].common_name, atnf_db.matched_pulsars[m].psrj_name,
                                  atnf_db.matched_pulsars[m].period_s, atnf_db.matched_pulsars[m].dm), UVM_NONE)
                end
            end else begin
                `uvm_info("SCB_ATNF_NEW",
                    $sformatf(">>> [ATNF-INFO] Detected period (%.6f s) does not match known bright catalogue pulsars (Possible New Candidate Discovery)",
                              act_item.period_s), UVM_NONE)
            end
        end
    endfunction : check_transactions

    // Final Report Phase
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "=================================================================", UVM_NONE)
        `uvm_info("SCB_REPORT", "             FFA ACCELERATOR UVM VERIFICATION REPORT             ", UVM_NONE)
        `uvm_info("SCB_REPORT", "=================================================================", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Total UART Frames Monitored    : %0d", total_frames_received), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Bit-Exact Hardware Matches      : %0d", bit_exact_matches), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Period Calculation Mismatches   : %0d", period_mismatches), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" Preamble Synchronization Errors : %0d", preamble_errors), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" UART Framing Protocol Errors    : %0d", framing_errors), UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" ATNF Catalogue Matches Resolved : %0d", atnf_matches_found), UVM_NONE)
        `uvm_info("SCB_REPORT", "-----------------------------------------------------------------", UVM_NONE)

        if (period_mismatches == 0 && preamble_errors == 0 && framing_errors == 0 && total_frames_received > 0) begin
            `uvm_info("SCB_REPORT", "                  >>> UVM VERIFICATION STATUS: PASSED <<<        ", UVM_NONE)
        end else if (total_frames_received == 0) begin
            `uvm_warning("SCB_REPORT", "              >>> UVM VERIFICATION STATUS: NO FRAMES PROCESSED <<<")
        end else begin
            `uvm_error("SCB_REPORT", "                  >>> UVM VERIFICATION STATUS: FAILED <<<        ")
        end
        `uvm_info("SCB_REPORT", "=================================================================", UVM_NONE)
    endfunction : report_phase

endclass : ffa_scoreboard

`endif // FFA_SCOREBOARD_SV
