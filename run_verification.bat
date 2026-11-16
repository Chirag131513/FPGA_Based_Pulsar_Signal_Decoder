@echo off
REM ==============================================================================
REM Script: run_verification.bat
REM Purpose: Windows single-command runner for FFA Accelerator UVM Verification
REM ==============================================================================

set SCRIPT_DIR=%~dp0
set SIM_DIR=%SCRIPT_DIR%uvm\sim

echo ========================================================================
echo     FFA ACCELERATOR: RUNNING FULL UVM 1.2 VERIFICATION ARCHITECTURE    
echo ========================================================================

cd /d "%SIM_DIR%"

where xrun >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Detected Cadence Xcelium (xrun). Executing Master Verification Test...
    xrun -f xrun_args.f +UVM_TESTNAME=ffa_master_verification_test +UVM_VERBOSITY=UVM_LOW -coverage all -covoverwrite -covworkdir cov_work -l xrun_verify.log
    
    echo ========================================================================
    echo  ATNF Catalogue Matching Summary & UVM Scoreboard Status:
    echo ========================================================================
    findstr /C:"[ATNF-SUCCESS]" /C:"[SCB_MATCH_EXACT]" /C:"SCB_REPORT" /C:"UVM VERIFICATION STATUS" xrun_verify.log
) else (
    echo [WARNING] Cadence Xcelium ('xrun') not detected in PATH.
    echo [INFO] Executing automated Python verification regression...
    python run_regression.py
)

cd /d "%SCRIPT_DIR%"
echo ========================================================================
echo  Verification execution completed.
echo ========================================================================
