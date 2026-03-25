@echo off
REM CARRY4 TDC compile and simulate batch script
REM Function: compile all Verilog files and run simulation

REM Set working directories
set WORK_DIR=d:\01-Codes\XilinxCode\Vernier_tdc\rtl\v4_carry4_tdc
set RTL_DIR=d:\01-Codes\XilinxCode\Vernier_tdc\rtl

REM Set ModelSim path
set MODELSIM_PATH=C:\modeltech64_2020.4\win64

REM Check if ModelSim is available
echo Checking ModelSim path: %MODELSIM_PATH%
if not exist "%MODELSIM_PATH%\vlog.exe" (
    echo Error: vlog.exe not found at %MODELSIM_PATH%
    echo Please set correct ModelSim path
    pause
    exit /b 1
)
if not exist "%MODELSIM_PATH%\vsim.exe" (
    echo Error: vsim.exe not found at %MODELSIM_PATH%
    echo Please set correct ModelSim path
    pause
    exit /b 1
)
echo ModelSim path check passed

REM Change to working directory
cd /d %WORK_DIR%\src

echo ========================================
echo CARRY4 TDC compile and simulate script
echo Working directory: %WORK_DIR%
echo ModelSim path: %MODELSIM_PATH%
echo Time unit: 1ns/1ps
echo ========================================
echo.

REM Create work library
echo [1/6] Creating work library...
if exist work rmdir /s /q work
%MODELSIM_PATH%\vlib.exe work
if errorlevel 1 (
    echo Error: Failed to create work library
    pause
    exit /b 1
)

echo [2/6] Compiling top module...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% tdc_top_carry4.v
if errorlevel 1 (
    echo Error: Failed to compile tdc_top_carry4.v
    pause
    exit /b 1
)

echo [3/6] Compiling core modules...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% carry4_delay_chain.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% coarse_counter_400m.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% edge_detector_sync.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% thermometer_decoder.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% timestamp_synthesizer_dual.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% clock_reference_gen.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% mmcm_50m_to_400m.v
if errorlevel 1 (
    echo Error: Failed to compile core modules
    pause
    exit /b 1
)

echo [4/6] Compiling testbench...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% tb_carry4_tdc.v
if errorlevel 1 (
    echo Error: Failed to compile testbench
    pause
    exit /b 1
)

echo [5/6] Starting simulation...
echo Starting ModelSim, please wait...
%MODELSIM_PATH%\vsim.exe -c -do "vsim work.tb_carry4_tdc; run -all; quit"
if errorlevel 1 (
    echo Warning: Simulation may have warnings
)

echo [6/6] Checking simulation results...
if exist tb_carry4_tdc.vcd (
    echo Simulation completed! Waveform file generated: tb_carry4_tdc.vcd
    echo You can use ModelSim to open the waveform file for detailed analysis
) else (
    echo Warning: Waveform file not generated, please check if simulation succeeded
)

echo.
echo ========================================
echo Compile and simulation completed!
echo ========================================
echo.
echo Generated files:
echo - work/: compiled library files
echo - tb_carry4_tdc.vcd: simulation waveform file
echo.
echo Next steps:
echo 1. Use ModelSim to open waveform file for analysis
echo 2. Check simulation output matches expectations
echo 3. If issues found, modify code and re-run this script
echo.

pause
