#!/bin/bash
# Script: run_xcelium.sh
# Purpose: Run Cadence Xcelium UVM 1.2 simulation for FFA Accelerator

TEST=${1:-ffa_sanity_test}
VERBOSITY=${2:-UVM_MEDIUM}
SEED=${3:-1}

echo "========================================================================"
echo " Starting Cadence Xcelium (xrun) Simulation"
echo " Test:      $TEST"
echo " Verbosity: $VERBOSITY"
echo " Seed:      $SEED"
echo "========================================================================"

xrun -f xrun_args.f \
    +UVM_TESTNAME=$TEST \
    +UVM_VERBOSITY=$VERBOSITY \
    -svseed $SEED \
    -l xrun_${TEST}_seed${SEED}.log

echo "========================================================================"
echo " Simulation Finished. Log: xrun_${TEST}_seed${SEED}.log"
echo "========================================================================"
