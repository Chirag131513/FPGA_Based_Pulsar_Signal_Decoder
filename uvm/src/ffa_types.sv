// File: ffa_types.sv
// Description: Type definitions, enumerations, and structs for UVM Testbench
// Author: Chirag131513
`ifndef FFA_TYPES_SV
`define FFA_TYPES_SV

package ffa_types_pkg;

    // FSM State enumeration matching ffa_engine
    typedef enum logic [2:0] {
        FFA_S_IDLE         = 3'b000,
        FFA_S_INIT_MEM     = 3'b001,
        FFA_S_ACQUIRE_DATA = 3'b010,
        FFA_S_FOLD_DATA    = 3'b011,
        FFA_S_DETECT_PEAK  = 3'b100,
        FFA_S_SEND_RESULT  = 3'b101,
        FFA_S_ILLEGAL      = 3'b111
    } ffa_fsm_state_e;

    // UART Transmitter FSM states matching uart_tx
    typedef enum logic [2:0] {
        UART_S_IDLE            = 3'b000,
        UART_S_START_BIT_BYTE  = 3'b001,
        UART_S_DATA_BITS_BYTE  = 3'b010,
        UART_S_STOP_BIT_BYTE   = 3'b011,
        UART_S_START_BIT_DATA  = 3'b100,
        UART_S_DATA_BITS       = 3'b101,
        UART_S_STOP_BIT_DATA   = 3'b110
    } uart_fsm_state_e;

    // Signal-to-Noise Ratio injection modes
    typedef enum {
        SNR_CLEAN,       // Pure periodic pulse, no noise
        SNR_HIGH,        // High SNR (> 15 dB), clearly visible peaks
        SNR_MEDIUM,      // Moderate SNR (~ 6 dB), peak near noise ceiling
        SNR_LOW,         // Low SNR (~ 0.5 dB), pulse buried within noise floor
        SNR_BURIED,      // Sub-zero SNR (-4 dB), detectable only via coherent folding
        SNR_PURE_NOISE   // No pulse present, false-positive detection test
    } snr_profile_e;

    // Prominent ATNF Pulsar catalogue identifiers
    typedef enum {
        PSR_CRAB_B0531_21,     // Crab Pulsar (33.39 ms)
        PSR_VELA_B0833_45,     // Vela Pulsar (89.33 ms)
        PSR_DOUBLE_J0737_3039A,// Double Pulsar A (1.589 s / 22.70 ms)
        PSR_B0329_54,          // Canonical Bright Pulsar (714.52 ms)
        PSR_B0950_08,          // Nearby Low-DM Pulsar (253.06 ms)
        PSR_B1937_21,          // First Millisecond Pulsar (1.558 ms)
        PSR_J0437_4715,        // Brightest MSP (5.757 ms)
        PSR_BELL_B1919_21,     // Discovery Pulsar (1337.3 ms)
        PSR_B1133_16,          // High Drift Pulsar (1187.9 ms)
        PSR_TEST_BENCHMARK     // Scaled verification benchmark
    } atnf_pulsar_id_e;

    // ATNF Pulsar Catalogue Record structure
    typedef struct {
        string           common_name;
        string           psrj_name;
        real             period_s;       // Barycentric period in seconds
        real             period_ms;      // Period in milliseconds
        real             period_us;      // Period in microseconds
        real             dm;             // Dispersion Measure (pc / cm^3)
        real             duty_cycle_pct; // Typical pulse width as % of period
        real             tolerance_pct;  // Matching tolerance
    } atnf_pulsar_entry_s;

    // Architectural parameter configuration
    typedef struct {
        int  data_buffer_size;
        int  profile_bins;
        int  num_trial_periods;
        int  clks_per_bit;
        real clk_freq_mhz;
        real clk_period_ns;
    } ffa_config_s;

endpackage : ffa_types_pkg

`endif // FFA_TYPES_SV
