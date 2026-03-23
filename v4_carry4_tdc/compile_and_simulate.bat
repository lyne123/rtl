@echo off
REM ===========================================================================
REM CARRY4 TDC 编译和仿真批处理脚本
REM 功能: 编译所有Verilog文件并运行仿真
REM 注意: 使用-timescale参数统一时间单位
REM ===========================================================================

REM 设置工作目录
set WORK_DIR=d:\01-Codes\XilinxCode\Vernier_tdc\rtl\v4_carry4_tdc
set RTL_DIR=d:\01-Codes\XilinxCode\Vernier_tdc\rtl

REM 设置ModelSim路径 (根据实际情况修改)
set MODELSIM_PATH=C:\modeltech64_10.7\win64

REM 检查ModelSim是否可用
if not exist "%MODELSIM_PATH%\vlog.exe" (
    echo Error: ModelSim not found at %MODELSIM_PATH%
    echo Please set correct ModelSim path
    pause
    exit /b 1
)

REM 切换到工作目录
cd /d %WORK_DIR%

echo =======================================
echo CARRY4 TDC 编译和仿真脚本
echo 工作目录: %WORK_DIR%
echo ModelSim路径: %MODELSIM_PATH%
echo 时间单位: 1ns/1ps
echo =======================================
echo.

REM 创建work库
echo [1/6] 创建work库...
if exist work rmdir /s /q work
%MODELSIM_PATH%\vlib.exe work
if errorlevel 1 (
    echo Error: Failed to create work library
    pause
    exit /b 1
)

echo [2/6] 编译顶层模块...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% tdc_top_carry4.v
if errorlevel 1 (
    echo Error: Failed to compile tdc_top_carry4.v
    pause
    exit /b 1
)

echo [3/6] 编译核心模块...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% carry4_delay_chain.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% coarse_counter_400m.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% edge_detector_sync.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% thermometer_decoder.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% timestamp_synthesizer.v
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% mmcm_50m_to_400m.v
if errorlevel 1 (
    echo Error: Failed to compile core modules
    pause
    exit /b 1
)

echo [4/6] 编译测试平台...
%MODELSIM_PATH%\vlog.exe -work work -timescale 1ns/1ps +incdir+%RTL_DIR% tb_carry4_tdc.v
if errorlevel 1 (
    echo Error: Failed to compile testbench
    pause
    exit /b 1
)

echo [5/6] 启动仿真...
echo 正在启动ModelSim，请稍候...
%MODELSIM_PATH%\vsim.exe -c -do "vsim work.tb_carry4_tdc; run -all; quit"
if errorlevel 1 (
    echo Warning: Simulation may have warnings
)

echo [6/6] 检查仿真结果...
if exist tb_carry4_tdc.vcd (
    echo 仿真完成! 波形文件已生成: tb_carry4_tdc.vcd
    echo 可以使用ModelSim打开波形文件查看详细结果
) else (
    echo Warning: 波形文件未生成，请检查仿真是否成功
)

echo.
echo =======================================
echo 编译和仿真完成!
echo =======================================
echo.
echo 文件生成情况:
echo - work/: 编译库文件
echo - tb_carry4_tdc.vcd: 仿真波形文件
echo.
echo 后续步骤:
echo 1. 使用ModelSim打开波形文件分析结果
echo 2. 检查仿真输出是否符合预期
echo 3. 如有问题，修改代码后重新运行此脚本
echo.

pause