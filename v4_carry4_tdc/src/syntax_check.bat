@echo off
REM 简单的Verilog语法检查脚本
REM 检查基本的语法错误

echo ========================================
echo Verilog语法检查
echo ========================================
echo.

set ERRORS=0

REM 检查每个Verilog文件的基本语法
for %%f in (*.v) do (
    echo 检查 %%f...

    REM 检查模块定义
    findstr /r /c:"^module" "%%f" >nul
    if errorlevel 1 (
        echo   [错误] %%f: 缺少module定义
        set /a ERRORS+=1
    ) else (
        echo   [通过] module定义
    )

    REM 检查endmodule
    findstr /r /c:"endmodule$" "%%f" >nul
    if errorlevel 1 (
        echo   [错误] %%f: 缺少endmodule
        set /a ERRORS+=1
    ) else (
        echo   [通过] endmodule定义
    )

    REM 检查括号匹配
    for /f %%i in ('findstr /n "(" "%%f" ^| find /c ":"') do set OPEN_PARENS=%%i
    for /f %%i in ('findstr /n ")" "%%f" ^| find /c ":"') do set CLOSE_PARENS=%%i

    if not "%OPEN_PARENS%"=="%CLOSE_PARENS%" (
        echo   [警告] %%f: 括号可能不匹配 (%OPEN_PARENS% vs %CLOSE_PARENS%)
    ) else (
        echo   [通过] 括号匹配
    )

    echo.
)

echo ========================================
if %ERRORS% equ 0 (
    echo 语法检查完成：所有文件通过基本检查
) else (
    echo 语法检查完成：发现 %ERRORS% 个错误
)
echo ========================================

pause