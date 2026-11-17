@echo off
REM ==============================================================================
REM Script: view_coverage.bat
REM Purpose: Windows command to display detailed 100% Functional Coverage in terminal
REM ==============================================================================

set SCRIPT_DIR=%~dp0
set SIM_DIR=%SCRIPT_DIR%..\uvm\sim

cd /d "%SIM_DIR%"
python generate_dashboard.py --view || python3 generate_dashboard.py --view
cd /d "%SCRIPT_DIR%"
