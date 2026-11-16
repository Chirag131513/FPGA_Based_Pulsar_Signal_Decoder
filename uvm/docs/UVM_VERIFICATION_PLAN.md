# UVM 1.2 Verification Plan: FPGA Fast Folding Algorithm (FFA) Accelerator

**Author**: FPGA Research Intern | MIT Manipal  
**Project**: FFA Accelerator — Deep Space Navigation & Pulsar Detection  
**Verification Standard**: IEEE 1800.2 / UVM 1.2  
**Target Simulator**: Cadence Xcelium (`xrun`) / Synopsys VCS / Mentor Questa  

---

## 1. Executive Summary

This verification dossier details the production-grade **UVM 1.2 testbench** designed to verify the **FPGA Hardware Accelerator for the Fast Folding Algorithm (FFA)**. The hardware accelerator accelerates the detection of periodic, dispersed radio signals emitted by rapidly rotating neutron stars (pulsars) for deep space navigation and timekeeping.

### Core Verified Subsystems:
* **5-State FSM Folding Engine**: Supports up to 16k time-series buffer (`DATA_BUFFER_SIZE = 16384`), 2,048 trial periods (`NUM_TRIAL_PERIODS = 2048`), and 256 folded profile phase bins (`PROFILE_BINS = 256`).
* **50 MHz UART Transmitter**: Transmits detected periods with a mandatory `0xAA` preamble synchronization byte, 32-bit little-endian payload, and 9600 baud rate framing.
* **Dual-Domain UVM Environment**:
  - **Constrained-Random Noisy Signal Generator**: Simulates realistic astronomical RF signal feeds across 5 SNR regimes (Clean, High, Medium, Low, Buried/Sub-zero SNR).
  - **SystemVerilog Assertion (SVA) Protocol Monitors**: Exhaustive temporal checks on FSM state sequences, buffer address bounds, and UART framing.
  - **Scoreboard with ATNF Catalogue Cross-Referencing**: Performs bit-exact validation against a software golden folding model and cross-references detected periods against the Australia Telescope National Facility (ATNF) database.

---

## 2. UVM 1.2 Testbench Architecture

```
                                  +-------------------------------------------------------------+
                                  |                     ffa_tb_top                              |
                                  |                                                             |
                                  |  +--------------------+         +------------------------+  |
                                  |  |   clk_50mhz (20ns) |         |     ffa_sva Checker    |  |
                                  |  |   Synchronous Reset|         | (FSM, UART, Buffers)   |  |
                                  |  +---------+----------+         +-----------^------------+  |
                                  |            |                                | (Probe signals|
                                  |            v                                |  hierarchically)
                                  |  +------------------------------------------+------------+  |
                                  |  |                 ffa_if (SystemVerilog Interface)       |  |
                                  |  +---------------------+--------------------+------------+  |
                                  |                        |                    |               |
                                  |           adc_data_in  |                    | uart_tx_pin   |
                                  |                        v                    ^               |
                                  |  +---------------------+--------------------+------------+  |
                                  |  |              DUT: top (FFA Engine + UART TX)          |  |
                                  |  +-------------------------------------------------------+  |
                                  +-------------------------------------------------------------+
                                                               ^
                                                               | (Virtual Interface vif)
+--------------------------------------------------------------+--------------------------------------------------------------+
|                                                      ffa_env                                                                |
|                                                                                                                             |
|  +--------------------------------+       +-------------------------+       +--------------------------------------------+  |
|  |           adc_agent            |       |      ffa_ref_model      |       |               ffa_scoreboard               |  |
|  |  +--------------------------+  |       | (Golden Software FFA)   |       |  +--------------------------------------+  |  |
|  |  |     ffa_adc_sequencer    |  |       |                         |       |  | Bit-Exact Hardware Comparator        |  |  |
|  |  +------------+-------------+  |       | - Emulates folding      |       |  +--------------------------------------+  |  |
|  |               |                |       | - Emulates peak search  |       |  | ATNF Pulsar Database Cross-Ref       |  |  |
|  |  +------------v-------------+  |       | - Predicts period & pwr |       |  | (PSR J0737, Crab, Vela, B0329, etc.) |  |  |
|  |  |      ffa_adc_driver      |  |       +------------^------------+       +---------------------^----------------------+  |
|  |  +--------------------------+  |                    | Expected Item                            | Actual Item         |  |
|  |                                |                    | (exp_export)                             | (act_export)        |  |
|  |  +--------------------------+  |                    |                                          |                     |  |
|  |  |      ffa_adc_monitor     +--+--------------------+                                          |                     |  |
|  |  +--------------------------+  | Stimulus Stream                                               |                     |  |
|  +--------------------------------+                                                               |                     |  |
|                                                                                                   |                     |  |
|  +------------------------------------------------------------------------------------------------+                     |  |
|  |           uart_agent (Passive)                                                                                       |  |
|  |  +---------------------------------------------------------------------------------------+                           |  |
|  |  |                                    ffa_uart_monitor                                   |                           |  |
|  |  | - Deserializes 9600 baud line stream                                                   |                           |  |
|  |  | - Validates 0xAA preamble sync & 32-bit payload framing                                |                           |  |
|  |  +---------------------------------------------------------------------------------------+                           |  |
|  +----------------------------------------------------------------------------------------------------------------------+  |
|                                                                                                                             |
|  +-----------------------------------------------------------------------------------------------------------------------+  |
|  |                                                 ffa_coverage                                                          |  |
|  |  - Stimulus Covergroup: Buffer sizes, trial periods, duty cycles, SNR modes, ATNF target cross-coverages              |  |
|  |  - Response Covergroup: Preamble validation, framing status, detected period distribution                             |  |
|  +-----------------------------------------------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------------------------------------------+
```

---

## 3. Constrained-Random Noisy Signal Models

Radio astronomical signals captured by radio telescopes (e.g. GMRT, Parkes, Arecibo) are characterized by extremely weak periodic pulses deeply immersed in Gaussian thermal noise and galactic synchrotron background emission.

The UVM sequence item (`ffa_adc_item`) models these astrophysical phenomena through parameterized random variables and mathematical post-randomization:

$$\text{Sample}[i] = \text{Clamp}_{0}^{255} \Big( \text{Pulse}[i \pmod P] + \text{Noise}[i] \Big)$$

### Verification SNR Regimes:
| SNR Regime | Peak-to-Noise Ratio | Astrophysical Analogue | Verification Objective |
|------------|---------------------|------------------------|------------------------|
| `SNR_CLEAN` | $+30\text{ dB}$ (No noise) | Idealized laboratory test | Baseline functional sanity |
| `SNR_HIGH` | $+15\text{ dB}$ | Bright nearby pulsars (B0329+54) | Standard folding verification |
| `SNR_MEDIUM` | $+6\text{ dB}$ | Moderate pulsars (Vela B0833-45) | Profile accumulation dynamics |
| `SNR_LOW` | $0.5\text{ dB}$ | Weak pulsars (Crab B0531+21) | Detectability at noise threshold |
| `SNR_BURIED` | $-4\text{ dB}$ (Sub-zero) | Distant deep-space sources | Proves folding algorithm gain ($G \propto \sqrt{N}$) |
| `SNR_PURE_NOISE`| $-\infty\text{ dB}$ | Off-target sky pointing | False-positive candidate rejection |

---

## 4. SystemVerilog Assertions (SVA) Specification

Temporal protocol rules and safety assertions are implemented in `ffa_sva.sv`:

| Assertion Name | Property Tested | Severity |
|----------------|-----------------|----------|
| `a_reset_state` | Asserts FSM reaches `S_IDLE`, `tx_start == 0`, and `buffer_write_addr == 0` during reset. | Fatal/Error |
| `a_uart_idle_after_reset` | Ensures UART physical pin remains logic `1` while transmitter is idle. | Error |
| `a_fsm_legal_state` | Restricts FSM state encoding to valid states `{3'b000 .. 3'b100}` (no deadlocks in 101, 110, 111). | Error |
| `a_fsm_idle_to_acquire` | Checks deterministic transition `S_IDLE` $\rightarrow$ `S_ACQUIRE_DATA` upon reset release. | Error |
| `a_fsm_acquire_to_fold` | Validates transition `S_ACQUIRE_DATA` $\rightarrow$ `S_FOLD_DATA` occurs exactly when buffer is full. | Error |
| `a_buffer_addr_in_bounds` | Proves `buffer_write_addr` never overflows `DATA_BUFFER_SIZE - 1`. | Error |
| `a_send_result_handshake` | Ensures `S_SEND_RESULT` immediately asserts `tx_start` when `!tx_busy`. | Error |
| `a_tx_start_pulse_width` | Proves `tx_start` is strictly an atomic single-cycle pulse. | Error |
| `a_tx_start_triggers_busy` | Verifies UART core responds with `tx_busy == 1` within 1 cycle of `tx_start`. | Error |
| `a_detected_period_valid` | Asserts detected period is non-zero upon peak identification. | Warning |

---

## 5. ATNF Pulsar Database Cross-Referencing

The scoreboard integrates the **ATNF Pulsar Catalogue** database (`ffa_atnf_catalogue.sv`). When the hardware detects a period from the folded profile and transmits it via UART, the scoreboard automatically converts the period from microseconds into seconds and evaluates:

$$\Delta P_{\text{rel}} = \frac{|P_{\text{cat}} - P_{\text{meas}}|}{P_{\text{cat}}} \le 5.0\%$$

### Catalogued Reference Sources:
1. **PSR J0737-3039A**: Double Pulsar relativistic binary ($P_0 = 1.589\text{ s}$ demo mode / $22.70\text{ ms}$, $\text{DM} = 48.92\text{ pc/cm}^3$)
2. **PSR B0531+21 (Crab Pulsar)**: Supernova remnant core ($P_0 = 33.39\text{ ms}$, $\text{DM} = 56.77\text{ pc/cm}^3$)
3. **PSR B0833-45 (Vela Pulsar)**: Gamma/radio beacon ($P_0 = 89.33\text{ ms}$, $\text{DM} = 67.99\text{ pc/cm}^3$)
4. **PSR B0329+54**: Northern sky primary standard candle ($P_0 = 714.52\text{ ms}$, $\text{DM} = 26.76\text{ pc/cm}^3$)
5. **PSR B0950+08**: Low interstellar dispersion reference ($P_0 = 253.06\text{ ms}$, $\text{DM} = 2.97\text{ pc/cm}^3$)
6. **PSR B1937+21**: High-frequency millisecond pulsar ($P_0 = 1.558\text{ ms}$, $\text{DM} = 71.02\text{ pc/cm}^3$)
7. **PSR B1919+21 (LGM-1)**: Historic discovery pulsar by Bell Burnell ($P_0 = 1.337\text{ s}$, $\text{DM} = 12.43\text{ pc/cm}^3$)

If a detected period falls within the $5\%$ tolerance window, the scoreboard prints:
```
[SCB_ATNF_MATCH] >>> [ATNF-SUCCESS] Cross-referenced detected period (1.589000 s) with ATNF catalogue: Found 1 match(es):
    -> J0737-3039A (PSR J0737-3039A) | P0 = 1.589000 s | DM = 48.92 pc/cm^3
```
Otherwise, the detection is classified as a prospective **New Candidate Discovery**.

---

## 6. Test Suite & Coverage Plan

### Implemented UVM Tests:
1. **`ffa_sanity_test`**:
   - Executes standard deterministic benchmark ($P = 1600\ \mu\text{s}$).
   - Validates baseline reset, memory clearing, acquisition, folding, peak search, and UART deserialization.
2. **`ffa_random_noisy_test`**:
   - Runs constrained-random iterations sweeping through SNR regimes (`SNR_HIGH`, `SNR_MEDIUM`, `SNR_LOW`, `SNR_BURIED`).
   - Verifies hardware folding gain and robustness against background Gaussian noise.
3. **`ffa_atnf_test`**:
   - Injects realistic celestial pulsar periods and validates ATNF catalogue resolution in the scoreboard.
4. **`ffa_stress_test`**:
   - Stresses edge cases: minimum pulse widths, buried negative SNR, and pure background noise.

---

## 7. Cadence Xcelium Execution Commands

To execute simulation in Cadence Xcelium (`xrun`):

```bash
cd uvm/sim

# 1. Run Sanity Test
xrun -f xrun_args.f +UVM_TESTNAME=ffa_sanity_test

# 2. Run Constrained-Random Noisy Test with Custom Seed
xrun -f xrun_args.f +UVM_TESTNAME=ffa_random_noisy_test -svseed 101

# 3. Run ATNF Catalogue Test with Code Coverage
xrun -f xrun_args.f +UVM_TESTNAME=ffa_atnf_test -coverage all -covoverwrite

# 4. Launch Full Automated Regression Suite
python run_regression.py
```
