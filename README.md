# FFA Accelerator — FPGA-Based Fast Folding Algorithm for Pulsar Signal Detection

**FPGA Implementation of the Fast Folding Algorithm (FFA) for real-time pulsar signal detection with UART data transmission and Python-based ATNF catalogue matching.**

![Language](https://img.shields.io/badge/Language-Verilog%20%7C%20SystemVerilog%20%7C%20Python-blue)
![Methodology](https://img.shields.io/badge/Methodology-UVM%201.2%20%7C%20SVA%20%7C%20Xcelium-darkgreen)
![Verification](https://img.shields.io/badge/Verification-Cadence%20Xcelium%20UVM%201.2-orange)
![Coverage](https://img.shields.io/badge/Coverage-Constrained--Random%20%2B%20SVA-brightgreen)
![License](https://img.shields.io/badge/License-MIT-red)

---

## Overview

This project implements an FPGA hardware accelerator for the **Fast Folding Algorithm (FFA)** — a technique for detecting periodic signals from deep-space pulsars buried in cosmic radio noise. The design targets FPGA deployment for real-time pulsar detection and deep-space navigation, verified with a **modular UVM 1.2 testbench in Cadence Xcelium**:

- **Synthesizable RTL** in Verilog with 5-state FSM folding engine (supporting up to 16k buffer, 2,048 trial periods, and 256 bins)
- **Complete UART transmitter** with start-byte framing (0xAA) for 50 MHz serial communication (9600 baud)
- **Modular UVM 1.2 Testbench** targeting Cadence Xcelium with:
  - Constrained-random noisy signal models (Gaussian noise floor + periodic pulse across 5 SNR regimes)
  - SystemVerilog Assertion (SVA) monitors for FSM state transitions, buffer boundaries, and UART framing
  - Golden Reference Model predicting folded profiles and peak detection
  - Scoreboard cross-referencing detected periods against the official **ATNF Pulsar Catalogue**
- **Python backend** for UART reception and live ATNF catalogue matching (`psrqpy`)
- **Direct legacy simulation** via Icarus Verilog (`tb_top.v`) and automated runner scripts

The FFA works by folding time-series data at multiple trial periods to enhance weak periodic signals that would otherwise be buried in noise. When a peak is detected in the folded profile, the corresponding trial period is transmitted via UART to a host computer for pulsar identification.

---

## Repository Structure

```
├── Design/
│   ├── ffa_engine.v              # FFA core: folding algorithm & peak detection FSM
│   ├── uart_tx.v                 # UART transmitter with start-byte framing
│   └── top.v                     # Parameterized top-level module integrating FFA + UART
├── uvm/
│   ├── tb_top.sv                 # Unified Top-Level UVM 1.2 Testbench (DUT, SVA, clk/rst, run_test)
│   ├── ffa_if.sv                 # SystemVerilog interface with clocking blocks & modports
│   ├── ffa_sva.sv                # Temporal SVA monitors (FSM, buffer overflow, UART framing)
│   ├── src/
│   │   ├── ffa_types.sv          # Types, enums, structs for SNR and ATNF catalogue
│   │   ├── ffa_pkg.sv            # Master UVM package
│   │   ├── ffa_adc_item.sv       # Constrained-random noisy signal stimulus item
│   │   ├── ffa_uart_item.sv      # UART transaction item
│   │   ├── ffa_adc_driver.sv     # UVM Driver for ADC streaming
│   │   ├── ffa_adc_monitor.sv    # UVM Monitor for ADC input stream
│   │   ├── ffa_uart_monitor.sv   # UVM Monitor for UART deserialization & framing
│   │   ├── ffa_adc_agent.sv      # Active UVM Agent
│   │   ├── ffa_uart_agent.sv     # Passive UVM Agent
│   │   ├── ffa_ref_model.sv      # Golden Reference Model for software FFA prediction
│   │   ├── ffa_atnf_catalogue.sv # ATNF Pulsar reference database
│   │   ├── ffa_scoreboard.sv     # UVM Scoreboard with bit-exact & ATNF cross-referencing
│   │   ├── ffa_coverage.sv       # Functional coverage subscriber
│   │   ├── ffa_env.sv            # UVM Environment
│   │   ├── ffa_sequence.sv       # Sequences: Sanity, Random Noisy, ATNF, Stress
│   │   └── tests/                # Test library: Master, Sanity, Noisy, ATNF, Stress
│   ├── sim/
│   │   ├── Makefile              # Cadence Xcelium, VCS, Questa targets
│   │   ├── xrun_args.f           # Cadence Xcelium xrun argument file
│   │   ├── run_xcelium.sh        # Linux Xcelium runner
│   │   ├── run_xcelium.bat       # Windows Xcelium runner
│   │   └── run_regression.py     # Python automated regression suite & report generator
│   └── docs/
│       └── UVM_VERIFICATION_PLAN.md # Publication-grade UVM verification plan
├── Backend/
│   └── backend.py                # Python script: UART receiver + ATNF catalogue query
├── run_verification.sh           # [SINGLE COMMAND] Full UVM Verification + ATNF + Coverage
├── run_waveform.sh               # [SEPARATE COMMAND] Dump & Launch SimVision / GTKWave
├── run_verification.bat          # Windows full verification runner
├── run_waveform.bat              # Windows waveform launcher
├── Makefile                      # Root Makefile (make verify, make wave, make cov)
├── References/
│   └── ffa.mlx                   # Supporting documentation / MLX configuration
├── LICENSE                       # MIT License
└── README.md
```

---

## Design Architecture

### Top-Level Module (`top.v`)

Structural integration of two main submodules:

```
top
├── ffa_engine    — FFA algorithm core (folding + peak detection)
└── uart_tx       — UART transmitter with 0xAA start-byte framing
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| Clock | 50 MHz | System clock (CLK_PERIOD = 20 ns) |
| Data width | 8 bits | ADC input data from telescope/sensor |
| UART baud | 9600 | Serial communication rate |
| Frame format | 1 start bit + 32 data bits + 1 stop bit | With 0xAA preamble |

---

### FFA Engine (`ffa_engine.v`)

Implements the complete Fast Folding Algorithm pipeline:

#### State Machine

| State | Encoding | Function |
|-------|----------|----------|
| `S_IDLE` | 3'b000 | Initialize flags, transition to acquisition |
| `S_ACQUIRE_DATA` | 3'b001 | Fill data buffer with ADC samples (16,384 samples) |
| `S_FOLD_DATA` | 3'b010 | Fold data into profile bins for multiple trial periods |
| `S_DETECT_PEAK` | 3'b011 | Search profile memory for maximum power bin |
| `S_SEND_RESULT` | 3'b100 | Transmit detected period via UART |

#### Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `DATA_BUFFER_SIZE` | 16,384 | Input time-series buffer depth |
| `PROFILE_BINS` | 256 | Number of phase bins per folded profile |
| `NUM_TRIAL_PERIODS` | 2,048 | Number of trial periods to search |
| `PROFILE_MEM_SIZE` | 524,288 | Total profile memory entries (2048 × 256) |

#### Memory Initialization

Uses **synthesizable generate block** for zero-initialization at reset:

```verilog
genvar g;
generate
  for (g = 0; g < PROFILE_MEM_SIZE; g = g + 1) begin : mem_init
    always @(posedge clk) begin
      if (rst) begin
        profile_memory[g] <= 32'd0;
      end
    end
  end
endgenerate
```

#### Folding Algorithm

1. Iterates through trial periods (10 to 2,048 cycles)
2. For each trial period, accumulates ADC data into phase bins
3. Uses modular arithmetic: `bin_index = sample_index % trial_period`
4. Stores accumulated power in `profile_memory[trial_period * PROFILE_BINS + bin]`

#### Peak Detection

1. Scans entire profile memory for maximum value
2. Records trial period index corresponding to peak
3. Converts trial period index to microseconds (scaling factor: 100 µs per index)

#### Handshake Signals

- `folding_done`: Flags completion of folding stage
- `peak_done`: Flags completion of peak detection
- `tx_start` / `tx_busy`: Flow control with UART transmitter

---

### UART Transmitter (`uart_tx.v`)

Implements asynchronous serial communication with frame synchronization:

#### State Machine

| State | Encoding | Function |
|-------|----------|----------|
| `S_IDLE` | 3'b000 | Wait for tx_start, assert tx_busy |
| `S_START_BYTE` | 3'b001 | Transmit 0xAA (10101010) for frame sync |
| `S_START_BIT` | 3'b010 | Transmit start bit (logic 0) for data frame |
| `S_DATA_BITS` | 3'b011 | Shift out 32-bit data (LSB first) |
| `S_STOP_BIT` | 3'b100 | Transmit stop bit (logic 1), return to IDLE |

#### Frame Format

```
[Idle High] [Start Byte: 0xAA] [Start Bit: 0] [32-bit Data] [Stop Bit: 1] [Idle High]
     1            8 bits            1 bit         32 bits        1 bit       1
```

**Timing:**
- `CLKS_PER_BIT = 5208` → 9600 baud @ 50 MHz clock
- Each bit held for 5208 clock cycles (104.16 µs)
- Total frame time: ~42 bit-times ≈ 4.375 ms

---

## Verification Environment

### Testbench (`tb_top.v`)

Generates realistic pulsar-like signal for functional verification:

#### Signal Model

- **Pulsar Period:** 1,590 µs (simulated)
- **Pulse Width:** 50 µs (duty cycle ≈ 3.1%)
- **Pulse Amplitude:** 8'hA0 + random(0–15) → range 160–175
- **Noise Floor:** 8'h10 + random(0–31) → range 16–47

#### Test Sequence

1. **Reset Phase** (200 ns): Assert reset, drive ADC input to 0
2. **Data Acquisition**: Generate 16,384 samples of pulse+noise signal
   - Samples synchronized to 50 MHz clock
   - Pulse active for `(i % period_cycles) < pulse_width_cycles`
3. **Processing Wait** (1,000,000 ns): Allow FFA engine to fold, detect peak, transmit
4. **UART Monitor**: Detect start bit on negative edge of UART TX pin

#### Expected Behavior

- Buffer fills in ~327.68 µs (16,384 × 20 ns)
- Folding completes after iterating through all trial periods
- Peak detection identifies strongest periodic component
- UART transmits detected period as 32-bit value with 0xAA preamble

---

## Backend Software (`backend.py`)

Python script for receiving detected periods and identifying pulsars:

### Workflow

1. **UART Reception:**
   - Opens serial port at 9600 baud
   - Waits for start byte (0xAA) to synchronize frame
   - Reads 4 bytes (little-endian uint32) as period in microseconds

2. **Period Conversion:**
   - Converts µs → milliseconds for catalogue query
   - Example: raw value 1590000 µs → 1590.0 ms → 1.59 s

3. **ATNF Catalogue Query:**
   - Uses `psrqpy` library to query ATNF pulsar database
   - Searches for pulsars with period within ±0.5% tolerance
   - Prints matching pulsar names (PSRJ designation) and known periods

### Dependencies

```bash
pip install pyserial psrqpy
```

### Usage

```bash
# Edit SERIAL_PORT to match your FPGA's USB-UART device
python backend.py
```

**Example Output:**
```
Listening on /dev/ttyUSB0...
 Received raw value: 1590000
Searching ATNF Catalogue for period: 1.590000 s...
 Success! Found 1 match(es):
  -> J0737-3039A (PSR J0737-3039A) | Known Period: 1.589 s
--------------------------------------------------
```

---

## Simulation Results

### Coverage Metrics

| Metric | Target | Achieved |
|--------|--------|----------|
| State transitions covered | All 5 states | ✅ 100% |
| Memory initialization | All addresses zeroed | ✅ Verified |
| UART frame transmission | Start byte + 32-bit data | ✅ Verified |
| Peak detection accuracy | Correct trial period | ✅ Within tolerance |

### Waveform Analysis

Key signals to observe in VCD file:

- `current_state`: Progress through FSM states
- `buffer_write_addr`: Monotonic increment during acquisition
- `fold_bin_addr` / `trial_period`: Nested loop counters during folding
- `max_power` / `detected_period`: Peak detection results
- `tx_out`: UART waveform with 0xAA preamble

---

## Synthesis Considerations

### Resource Utilization Estimates

| Resource | Estimated Count | Notes |
|----------|----------------|-------|
| Block RAM | 2–4 BRAMs | Profile memory (524K × 32-bit) may require distributed RAM or external BRAM |
| Flip-Flops | ~500 | Control logic, counters, state registers |
| LUTs | ~2,000 | Arithmetic operations, comparators, muxes |
| DSP Slices | 0 | No multiplication; only addition/comparison |

### Timing Constraints

- **Clock Period:** 20 ns (50 MHz)
- **Critical Path:** Profile memory read-modify-write in folding loop
- **Recommendation:** Use pipelined accumulation or dual-port BRAM for higher frequencies

### Memory Optimization

For larger FPGAs, consider:
- Inferring Block RAM with `(* ram_style = "block" *)` attribute
- Reducing `PROFILE_BINS` or `NUM_TRIAL_PERIODS` for resource-constrained devices
- Using cascaded accumulators to avoid simultaneous memory access

---

## References

| Document | Description |
|----------|-------------|
| `ffa.mlx` | MLX configuration / supporting methodology document |
| Staelin & Price (1970) | Original Fast Folding Algorithm paper |
| Lorimer & Kramer (2005) | Handbook of Pulsar Astronomy, Chapter 5 (FFA implementation) |
| ATNF Pulsar Catalogue | https://www.atnf.csiro.au/people/pulsar/psrcat/ |

---

## License

**MIT License** — see [LICENSE](LICENSE) for full terms.

---

## Quick Start Guide

### 🚀 1. The Single Verification Command (Lab Computer)
To run the **entire verification architecture** (stimulus, SVA monitors, Golden model, ATNF database matching, and code/functional coverage report):

```bash
# In the repository root:
chmod +x run_verification.sh run_waveform.sh
./run_verification.sh

# OR using Make:
make verify
```

**What this single command executes:**
1. Compiles RTL, SVA assertions, and UVM 1.2 testbench in **Cadence Xcelium (`xrun`)**.
2. Executes [`ffa_master_verification_test`](uvm/src/tests/ffa_master_verification_test.sv) running:
   - Sanity benchmark ($P = 1600\ \mu\text{s}$)
   - Real ATNF pulsar catalogue injection (PSR J0737-3039A, Crab B0531+21, Vela B0833-45, B0329+54, B1937+21)
   - Constrained-random noisy signal sweeps across 5 SNR regimes (Clean $\to$ High $\to$ Medium $\to$ Low $\to$ Buried sub-zero SNR)
   - Pure noise & false-positive candidate rejection checks
3. Concurrently collects full **Code Coverage & Functional Covergroups** into `cov_work/`.
4. Automatically invokes **Cadence IMC** in batch mode to print `cov_summary.txt`.
5. Prints the scoreboard pass/fail summary and live **ATNF Catalogue Potential Matches** directly to your console.

---

### 🌊 2. The Waveform Command (Separate Command)
To dump waveforms and launch the visual waveform viewer (**Cadence SimVision** or GTKWave):

```bash
# In the repository root:
./run_waveform.sh

# OR using Make:
make wave
```

---

### 3. Individual Test Execution & Regressions
If you wish to run individual tests from `uvm/sim/`:

```bash
cd uvm/sim

# Run specific tests with custom seeds:
xrun -f xrun_args.f +UVM_TESTNAME=ffa_sanity_test
xrun -f xrun_args.f +UVM_TESTNAME=ffa_random_noisy_test -svseed 101
xrun -f xrun_args.f +UVM_TESTNAME=ffa_atnf_test
xrun -f xrun_args.f +UVM_TESTNAME=ffa_stress_test

# Launch automated Python multi-seed regression:
python run_regression.py
```

### 2. Run Direct Testbench (Icarus Verilog)

```bash
# Using PowerShell runner:
.\run_sim.ps1

# Or using batch runner:
run_sim.bat

# Or direct invocation:
iverilog -o ffa_sim.vvp -I Design Design/*.v Testbench/tb_top.v
vvp ffa_sim.vvp
```

### 2. Synthesize for FPGA

```bash
# Example with Vivado (create project, add sources, run synthesis)
vivado -source scripts/synth.tcl
```

### 3. Deploy Backend

```bash
# Install dependencies
pip install pyserial psrqpy

# Configure serial port in backend.py
# Run script
python Backend/backend.py
```

---

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| No UART output detected | Reset not released | Ensure rst = 0 before stimulus |
| Incorrect period value | Scaling factor mismatch | Adjust `detected_period * 100` in `ffa_engine.v` |
| Backend cannot open port | Wrong device name | Check `/dev/tty*` or COM port in OS |
| No pulsar matches found | Period outside tolerance | Increase tolerance in `find_pulsar_in_catalogue()` |
| Synthesis fails on memory | Non-synthesizable loop | Verify generate block syntax (already fixed) |

---

## Contributing

Contributions welcome! Areas for improvement:
- Pipelined folding architecture for higher throughput
- Multi-channel FFA for parallel sky survey
- On-chip pulsar candidate ranking (reduce UART bandwidth)
- Integration with real ADC front-end (RF receiver chain)

---

**Project Status:** ✅ Functional verification complete | ⚠️ Synthesis tested (resource optimization recommended)
