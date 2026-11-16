@echo off
REM Script: run_xcelium.bat
REM Purpose: Windows Cadence Xcelium Runner for FFA Accelerator UVM Testbench

set TEST=%1
if "%TEST%"=="" set TEST=ffa_sanity_test

set VERBOSITY=%2
if "%VERBOSITY%"=="" set VERBOSITY=UVM_MEDIUM

set SEED=%3
if "%SEED%"=="" set SEED=1

echo ========================================================================
echo  Starting Cadence Xcelium (xrun) Simulation
echo  Test:      %TEST%
echo  Verbosity: %VERBOSITY%
echo  Seed:      %SEED%
echo ========================================================================

xrun -f xrun_args.f +UVM_TESTNAME=%TEST% +UVM_VERBOSITY=%VERBOSITY% -svseed %SEED% -l xrun_%TEST%_seed%SEED%.log

echo ========================================================================
echo  Simulation Finished.
echo ========================================================================
