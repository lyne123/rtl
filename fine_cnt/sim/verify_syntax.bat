@echo off
REM Syntax verification script for fine_counter_carry4 module

setlocal

REM Check if Vivado is available
where vivado >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Vivado not found in PATH
    exit /b 1
)

REM Create work directory if it doesn't exist
if not exist "work" mkdir work

REM Run syntax check using Vivado
vivado -mode batch -source verify_syntax.tcl

if %ERRORLEVEL% EQU 0 (
    echo Syntax verification PASSED
    exit /b 0
) else (
    echo Syntax verification FAILED
    exit /b 1
)

endlocal