#!/bin/bash
# ==============================================================================
# Script: view_coverage.sh
# Purpose: Display detailed 100% Functional Coverage Matrix in the terminal
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$(cd "$SCRIPT_DIR/../uvm/sim" && pwd)"

cd "$SIM_DIR"

if command -v python3 >/dev/null 2>&1; then
    python3 generate_dashboard.py --view
elif command -v python >/dev/null 2>&1; then
    python generate_dashboard.py --view
fi
