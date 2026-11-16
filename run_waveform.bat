@echo off
REM ==============================================================================
REM Script: run_waveform.bat
REM Purpose: Windows separate waveform runner
REM ==============================================================================

set SCRIPT_DIR=%~dp0
set SIM_DIR=%SCRIPT_DIR%uvm\sim

echo ========================================================================
echo     FFA ACCELERATOR: RUNNING SIMULATION WITH WAVEFORM PROBING          
echo ========================================================================

cd /d "%SIM_DIR%"

where xrun >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Running simulation with waveform dumping enabled...
    xrun -f xrun_args.f +UVM_TESTNAME=ffa_master_verification_test +define+DUMP_WAVES -access +rwc -linedebug -l xrun_wave.log
    
    where simvision >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        start simvision waves.shm
    ) else (
        where gtkwave >nul 2>nul
        if %ERRORLEVEL% EQU 0 (
            start gtkwave ffa_waves.vcd
        ) else (
            echo [INFO] Waveforms dumped: %SIM_DIR%\waves.shm and %SIM_DIR%\ffa_waves.vcd
        )
    )
) else (
    echo [WARNING] Cadence Xcelium not found in PATH.
    echo Running regression suite...
    python run_regression.py
)

cd /d "%SCRIPT_DIR%"
