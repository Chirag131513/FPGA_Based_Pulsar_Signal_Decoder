@echo off
REM ==============================================================================
REM Script: run_verification.bat
REM Purpose: Windows single-command runner for FFA Accelerator UVM Verification
REM ==============================================================================

set SCRIPT_DIR=%~dp0
set SIM_DIR=%SCRIPT_DIR%..\uvm\sim

echo ========================================================================
echo     FFA ACCELERATOR: RUNNING FULL UVM 1.2 VERIFICATION ARCHITECTURE    
echo ========================================================================

cd /d "%SIM_DIR%"

where xrun >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Detected Cadence Xcelium (xrun). Executing Master Verification Test...
    xrun -f xrun_args.f +UVM_TESTNAME=ffa_master_verification_test +UVM_VERBOSITY=UVM_LOW -l xrun_verify.log
    python generate_dashboard.py || python3 generate_dashboard.py
) else (
    echo [WARNING] Cadence Xcelium ('xrun') not detected in PATH.
    echo [INFO] Executing automated Python verification regression...
    python run_regression.py
)

cd /d "%SCRIPT_DIR%"
echo ========================================================================
echo  Verification execution completed.
echo ========================================================================
