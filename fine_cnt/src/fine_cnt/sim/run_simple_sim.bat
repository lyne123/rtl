@echo off
REM 简单仿真脚本

REM 使用 iverilog 编译（如果可用）
where iverilog >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo 使用 iverilog 进行仿真...
    iverilog -o sim_output ../src/fine_counter_carry4.v tb_fine_counter_simple.v
    if %ERRORLEVEL% EQU 0 (
        vvp sim_output
    ) else (
        echo 编译失败
    )
) else (
    echo iverilog 未找到
    echo 请使用 Vivado 进行仿真
    echo 建议命令: vivado -mode batch -source run_simulation.tcl
)

pause