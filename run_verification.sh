#!/bin/bash
# ==============================================================================
# Script: run_verification.sh
# Purpose: SINGLE COMMAND to execute the full UVM 1.2 verification architecture,
#          ATNF catalogue cross-referencing, and generate executive HTML dashboard.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/uvm/sim"

echo "========================================================================"
echo "    FFA ACCELERATOR: RUNNING FULL UVM 1.2 VERIFICATION ARCHITECTURE     "
echo "========================================================================"
echo " Directory: $SIM_DIR"

cd "$SIM_DIR"

# 1. Clean stale simulation artifacts so previous runs do not taint the new one
echo "[CLEAN] Purging stale simulation databases, history, and locks..."
rm -rf INCA_libs xcelium.d cov_work *.log *.history *.key *.shm *.vcd waves* cov_summary.txt .simvision* .bpad* *.diag *.dsn *.trn

# 2. Check if Cadence Xcelium is available
if command -v xrun >/dev/null 2>&1; then
    echo "[INFO] Detected Cadence Xcelium (xrun). Executing UVM Master Test..."
    
    xrun -f xrun_args.f \
        +UVM_TESTNAME=ffa_master_verification_test \
        +UVM_VERBOSITY=UVM_LOW \
        -l xrun_verify.log

    # 3. Generate Executive Summary & Clean White HTML Dashboard
    python3 generate_dashboard.py || python generate_dashboard.py || true
else
    echo "[WARNING] Cadence Xcelium ('xrun') not detected in PATH."
    echo "[INFO] Executing automated Python verification regression..."
    python3 run_regression.py
fi
