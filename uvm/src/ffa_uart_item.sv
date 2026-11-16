// File: ffa_uart_item.sv
// Description: UVM Sequence Item representing deserialized UART frame transactions
`ifndef FFA_UART_ITEM_SV
`define FFA_UART_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_uart_item extends uvm_sequence_item;
    `uvm_object_utils(ffa_uart_item)

    // Decoded UART frame fields
    bit [7:0]          preamble_byte;       // Expected 8'hAA
    bit [31:0]         period_raw;          // Raw 32-bit detected period
    bit                preamble_valid;      // 1 if preamble == 8'hAA
    bit                framing_valid;       // 1 if start and stop bits were valid
    
    // Physical engineering values
    real               period_us;           // Period in microseconds
    real               period_ms;           // Period in milliseconds
    real               period_s;            // Period in seconds

    // Timing metrics
    time               frame_start_time;
    time               frame_end_time;
    real               measured_baud_rate;

    function new(string name = "ffa_uart_item");
        super.new(name);
        preamble_byte   = 8'h00;
        period_raw      = 32'd0;
        preamble_valid  = 1'b0;
        framing_valid   = 1'b0;
        period_us       = 0.0;
        period_ms       = 0.0;
        period_s        = 0.0;
    endfunction : new

    function void calculate_units();
        period_us = real'(period_raw);
        period_ms = period_us / 1000.0;
        period_s  = period_ms / 1000.0;
    endfunction : calculate_units

    virtual function string convert2string();
        return $sformatf("[UART Frame] Preamble=0x%02H (Valid=%0b) Period_Raw=%0d (%.3f us / %.4f ms / %.6f s) FramingOK=%0b",
                         preamble_byte, preamble_valid, period_raw, period_us, period_ms, period_s, framing_valid);
    endfunction : convert2string

endclass : ffa_uart_item

`endif // FFA_UART_ITEM_SV
