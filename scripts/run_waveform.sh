#!/bin/bash
# ==============================================================================
# Script: run_waveform.sh
# Purpose: SEPARATE COMMAND to dump waveforms and launch Cadence SimVision / GTKWave
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$(cd "$SCRIPT_DIR/../uvm/sim" && pwd)"

echo "========================================================================"
echo "    FFA ACCELERATOR: RUNNING SIMULATION WITH WAVEFORM PROBING           "
echo "========================================================================"

cd "$SIM_DIR"

if command -v xrun >/dev/null 2>&1; then
    echo "[INFO] Running simulation with waveform probe enabled..."
    xrun -f xrun_args.f \
        +UVM_TESTNAME=ffa_master_verification_test \
        +define+DUMP_WAVES \
        -access +rwc \
        -linedebug \
        -l xrun_wave.log

    echo "========================================================================"
    echo " Launching Waveform Viewer..."
    echo "========================================================================"
    if command -v simvision >/dev/null 2>&1; then
        echo "[INFO] Opening Cadence SimVision..."
        simvision waves.shm &
    elif command -v gtkwave >/dev/null 2>&1; then
        echo "[INFO] Opening GTKWave..."
        gtkwave ffa_waves.vcd &
    else
        echo "[INFO] Waveform dumped successfully: $SIM_DIR/waves.shm and $SIM_DIR/ffa_waves.vcd"
        echo "Launch SimVision: simvision waves.shm"
        echo "Launch GTKWave:   gtkwave ffa_waves.vcd"
    fi
else
    echo "[WARNING] Cadence Xcelium not found. Simulating master UVM architecture via python regression runner..."
    python3 run_regression.py
fi
