@echo off
REM 简单的语法检查脚本

REM 检查 Verilog 语法基本错误
echo 检查 fine_counter_carry4.v 语法...

REM 使用 iverilog 进行基本语法检查（如果可用）
where iverilog >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    iverilog -o test.vvp ../src/fine_counter_carry4.v
    if %ERRORLEVEL% EQU 0 (
        echo 语法检查通过
    ) else (
        echo 语法检查失败
    )
) else (
    echo iverilog 未找到，跳过语法检查
    echo 建议使用 iverilog 或 Vivado 进行完整语法验证
)

pause