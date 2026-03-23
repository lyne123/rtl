# ModelSim仿真配置文件
# 用于VSCode和ModelSim联动

# 设置工程路径
set PROJECT_ROOT [pwd]
set RTL_PATH $PROJECT_ROOT
set WORK_LIB "work"

# 创建work库
if {[file exists $WORK_LIB]} {
    file delete -force $WORK_LIB
}
vlib $WORK_LIB
vmap work $WORK_LIB

# 编译TDC设计文件
proc compile_tdc {} {
    global RTL_PATH

    # 编译10ps TDC核心文件
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v3_10ps_vernier_tdc/vernier_tdc_10ps.v"
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v3_10ps_vernier_tdc/tb_10ps_test.v"

    # 编译进位链TDC (备选)
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v2_carry_chain_tdc/tdc_top.v"
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v2_carry_chain_tdc/tb_tdc_top.v"

    # 编译原始设计 (参考)
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v1_original_design/original_vernier_tdc.v"
    vlog -work work +incdir+$RTL_PATH "$RTL_PATH/v1_original_design/original_tdc_alignment.v"

    puts "✅ 所有TDC文件编译完成"
}

# 运行10ps TDC仿真
proc run_10ps_simulation {} {
    # 编译文件
    compile_tdc

    # 启动仿真
    vsim -t 1ps -voptargs="+acc" work.tb_10ps_test

    # 添加波形
    add wave -noupdate -divider "时钟和复位"
    add wave -noupdate /tb_10ps_test/clk
    add wave -noupdate /tb_10ps_test/rst_n

    add wave -noupdate -divider "TDC输入"
    add wave -noupdate /tb_10ps_test/start
    add wave -noupdate /tb_10ps_test/stop

    add wave -noupdate -divider "TDC输出"
    add wave -noupdate /tb_10ps_test/time_interval
    add wave -noupdate /tb_10ps_test/valid

    add wave -noupdate -divider "内部信号"
    add wave -noupdate /tb_10ps_test/uut/*

    # 运行仿真
    run -all

    puts "🎯 10ps TDC仿真完成"
}

# 运行进位链TDC仿真
proc run_carry_chain_simulation {} {
    # 编译文件
    compile_tdc

    # 启动仿真
    vsim -t 1ns -voptargs="+acc" work.tb_tdc_top

    # 添加波形
    add wave -noupdate -divider "系统信号"
    add wave -noupdate /tb_tdc_top/clk
    add wave -noupdate /tb_tdc_top/rst_n
    add wave -noupdate /tb_tdc_top/pwm

    add wave -noupdate -divider "TDC结果"
    add wave -noupdate /tb_tdc_top/timestamp
    add wave -noupdate /tb_tdc_top/valid

    # 运行仿真
    run -all

    puts "🚀 进位链TDC仿真完成"
}

# 快速测试特定时间间隔
proc test_specific_interval {interval_ps} {
    compile_tdc
    vsim -t 1ps work.tb_10ps_test

    # 强制设置特定的时间间隔进行测试
    force /tb_10ps_test/start 0 0, 1 1000
    force /tb_10ps_test/stop 0 0, 1 [expr $interval_ps + 1000]

    run 200ns

    puts "📊 测试 $interval_ps ps 时间间隔完成"
}

# 帮助信息
proc help {} {
    puts "\n=== ModelSim TDC仿真命令 ==="
    puts "compile_tdc                    - 编译所有TDC文件"
    puts "run_10ps_simulation            - 运行10ps TDC完整仿真"
    puts "run_carry_chain_simulation     - 运行进位链TDC仿真"
    puts "test_specific_interval N       - 测试N ps时间间隔"
    puts "help                           - 显示此帮助信息"
    puts "quit                           - 退出ModelSim"
    puts "================================\n"
}

# 启动时显示帮助
puts "\n🎯 TDC ModelSim仿真环境已加载"
puts "📁 工程路径: $PROJECT_ROOT"
puts "\n可用的仿真命令:"
help

# 设置仿真精度
set NumericStdNoWarnings 1
set StdArithNoWarnings 1