// File: ffa_atnf_catalogue.sv
// Description: ATNF (Australia Telescope National Facility) Pulsar Catalogue Reference Database
// Author: Chirag131513
`ifndef FFA_ATNF_CATALOGUE_SV
`define FFA_ATNF_CATALOGUE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import ffa_types_pkg::*;

class ffa_atnf_catalogue extends uvm_object;
    `uvm_object_utils(ffa_atnf_catalogue)

    atnf_pulsar_entry_s catalogue[$];

    function new(string name = "ffa_atnf_catalogue");
        super.new(name);
        populate_catalogue();
    endfunction : new

    // =========================================================================
    // Populate Reference Pulsar Database
    // =========================================================================
    function void populate_catalogue();
        atnf_pulsar_entry_s e;

        // 1. PSR J0737-3039A (Famous Double Pulsar System)
        e.common_name    = "J0737-3039A";
        e.psrj_name      = "PSR J0737-3039A";
        e.period_s       = 1.589000;
        e.period_ms      = 1589.00;
        e.period_us      = 1589000.0;
        e.dm             = 48.92;
        e.duty_cycle_pct = 4.2;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 2. Crab Pulsar (PSR B0531+21 / J0534+2200) - Young Supernova Remnant
        e.common_name    = "Crab";
        e.psrj_name      = "PSR B0531+21";
        e.period_s       = 0.033392;
        e.period_ms      = 33.392;
        e.period_us      = 33392.0;
        e.dm             = 56.77;
        e.duty_cycle_pct = 8.5;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 3. Vela Pulsar (PSR B0833-45 / J0835-4510) - High Energy Gamma/Radio
        e.common_name    = "Vela";
        e.psrj_name      = "PSR B0833-45";
        e.period_s       = 0.089328;
        e.period_ms      = 89.328;
        e.period_us      = 89328.0;
        e.dm             = 67.99;
        e.duty_cycle_pct = 5.0;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 4. PSR B0329+54 (J0332+5434) - Brightest standard candle in northern sky
        e.common_name    = "B0329+54";
        e.psrj_name      = "PSR B0329+54";
        e.period_s       = 0.714520;
        e.period_ms      = 714.520;
        e.period_us      = 714520.0;
        e.dm             = 26.76;
        e.duty_cycle_pct = 4.0;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 5. PSR B0950+08 (J0953+0755) - Extremely low dispersion measure
        e.common_name    = "B0950+08";
        e.psrj_name      = "PSR B0950+08";
        e.period_s       = 0.253065;
        e.period_ms      = 253.065;
        e.period_us      = 253065.0;
        e.dm             = 2.97;
        e.duty_cycle_pct = 6.0;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 6. PSR B1937+21 (J1939+2134) - First discovered Millisecond Pulsar (642 Hz)
        e.common_name    = "B1937+21 (MSP)";
        e.psrj_name      = "PSR B1937+21";
        e.period_s       = 0.001558;
        e.period_ms      = 1.558;
        e.period_us      = 1558.0;
        e.dm             = 71.02;
        e.duty_cycle_pct = 10.0;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 7. PSR J0437-4715 - Brightest Millisecond Pulsar
        e.common_name    = "J0437-4715";
        e.psrj_name      = "PSR J0437-4715";
        e.period_s       = 0.005757;
        e.period_ms      = 5.757;
        e.period_us      = 5757.0;
        e.dm             = 2.64;
        e.duty_cycle_pct = 12.0;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 8. PSR B1919+21 (J1921+2153) - Historical LGM-1 (Bell Burnell 1967)
        e.common_name    = "LGM-1 / B1919+21";
        e.psrj_name      = "PSR B1919+21";
        e.period_s       = 1.337302;
        e.period_ms      = 1337.302;
        e.period_us      = 1337302.0;
        e.dm             = 12.43;
        e.duty_cycle_pct = 3.5;
        e.tolerance_pct  = 5.0;
        catalogue.push_back(e);

        // 9. PSR J1600-3053 - Nanohertz Gravitational Wave Timing Reference
        e.common_name    = "J1600-3053";
        e.psrj_name      = "PSR J1600-3053";
        e.period_s       = 0.001600;
        e.period_ms      = 1.600;
        e.period_us      = 1600.0;
        e.dm             = 15.00;
        e.duty_cycle_pct = 5.0;
        e.tolerance_pct  = 10.0;
        catalogue.push_back(e);

        `uvm_info("ATNF_DB", $sformatf("Initialized ATNF Pulsar Reference Catalogue with %0d pulsars", catalogue.size()), UVM_MEDIUM)
    endfunction : populate_catalogue

    // =========================================================================
    // Query Catalogue by Period with Tolerance Window
    // =========================================================================
    function int query_catalogue(
        input  real                query_period_s,
        input  real                tolerance_pct,
        output atnf_pulsar_entry_s matches[$]
    );
        real error_pct;
        matches.delete();

        foreach (catalogue[i]) begin
            error_pct = ((query_period_s - catalogue[i].period_s) / catalogue[i].period_s) * 100.0;
            if (error_pct < 0.0) error_pct = -error_pct;

            if (error_pct <= tolerance_pct) begin
                matches.push_back(catalogue[i]);
            end
        end

        return matches.size();
    endfunction : query_catalogue

endclass : ffa_atnf_catalogue

`endif // FFA_ATNF_CATALOGUE_SV
