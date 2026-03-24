# ===========================================================================
# CARRY4 TDC 时序约束文件
# 目标芯片: xc7a100tfgg484-2
# 设计: 基于CARRY4进位链的高精度TDC
# ===========================================================================

# ===========================================================================
# 时钟定义
# ===========================================================================

# 50MHz输入时钟约束
create_clock -period 20.000 -name clk_50m [get_ports clk_50m]
set_clock_uncertainty 0.100 [get_clocks clk_50m]

# 400MHz输出时钟约束 (由MMCM生成)
create_clock -period 2.500 -name clk_400m [get_pins uut/u_mmcm/bufg_inst/O]
set_clock_uncertainty 0.050 [get_clocks clk_400m]

# 时钟组定义 (异步时钟)
set_clock_groups -asynchronous -group {clk_50m} -group {clk_400m}

# ===========================================================================
# 输入输出延迟约束
# ===========================================================================

# PWM输入信号约束
set_input_delay -clock clk_400m -max 2.0 [get_ports pwm_in]
set_input_delay -clock clk_400m -min -0.5 [get_ports pwm_in]
set_input_delay -clock clk_50m -max 5.0 [get_ports rst_n]

# 输出信号约束
set_output_delay -clock clk_400m -max 2.0 [get_ports time_interval*]
set_output_delay -clock clk_400m -max 2.0 [get_ports valid]

# ===========================================================================
# 异步路径约束
# ===========================================================================

# PWM信号异步输入约束
set_false_path -from [get_ports pwm_in] -to [get_registers *]
set_false_path -from [get_ports rst_n] -to [get_registers *]

# 跨时钟域路径约束
set_false_path -from [get_clocks clk_50m] -to [get_clocks clk_400m]
set_false_path -from [get_clocks clk_400m] -to [get_clocks clk_50m]

# ===========================================================================
# 多周期路径约束
# ===========================================================================

# 边沿检测同步器路径
set_multicycle_path 3 -setup -from [get_registers *pwm_sync_reg[0]*] -to [get_registers *pwm_sync_reg[2]*]
set_multicycle_path 2 -hold -from [get_registers *pwm_sync_reg[0]*] -to [get_registers *pwm_sync_reg[2]*]

# 粗计数器控制路径
set_multicycle_path 2 -setup -from [get_registers *start_edge_sync2*] -to [get_registers *counting_active*]
set_multicycle_path 1 -hold -from [get_registers *start_edge_sync2*] -to [get_registers *counting_active*]

# CARRY4延迟链接口路径 (方案一优化)
set_multicycle_path 3 -setup -from [get_pins *carry4_delay_chain*/carry_chain[*]] -to [get_registers *sample_reg1*]
set_multicycle_path 2 -hold -from [get_pins *carry4_delay_chain*/carry_chain[*]] -to [get_registers *sample_reg1*]

# CARRY4内部延迟路径约束
set_false_path -from [get_pins *carry4_delay_chain*/carry_chain[*]] -to [get_pins *carry4_delay_chain*/carry_chain[*]]

# 温度计码解码路径
set_multicycle_path 2 -setup -from [get_registers *thermometer_code*] -to [get_registers *binary_out*]
set_multicycle_path 1 -hold -from [get_registers *thermometer_code*] -to [get_registers *binary_out*]

# ===========================================================================
# 最大延迟约束
# ===========================================================================

# 边沿检测路径最大延迟
set_max_delay 5.0 -from [get_registers *pwm_sync_reg[2]*] -to [get_registers *start_edge_reg*]
set_max_delay 5.0 -from [get_registers *pwm_sync_reg[2]*] -to [get_registers *stop_edge_reg*]

# 温度计码解码路径最大延迟
set_max_delay 2.0 -from [get_ports *thermometer_in*] -to [get_ports *binary_out*]

# 时间合成路径最大延迟
set_max_delay 2.0 -from [get_ports *coarse_count*] -to [get_ports *timestamp*]
set_max_delay 2.0 -from [get_ports *fine_count*] -to [get_ports *timestamp*]

# ===========================================================================
# 时序例外约束
# ===========================================================================

# CARRY4延迟链内部路径 (纯组合逻辑，不需要时序约束)
set_false_path -from [get_pins *carry4_delay_chain*/carry_chain[*]] -to [get_registers *sample_reg1*]

# 计数器溢出检测路径
set_false_path -from [get_registers *count_value*] -to [get_registers *counting_active*]

# ===========================================================================
# 物理约束
# ===========================================================================

# 时钟网络约束
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_400m]

# I/O约束
set_property IOSTANDARD LVCMOS33 [get_ports clk_50m]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_in]
set_property IOSTANDARD LVCMOS33 [get_ports time_interval*]
set_property IOSTANDARD LVCMOS33 [get_ports valid]

# 引脚位置约束 (根据实际硬件设计修改)
# set_property PACKAGE_PIN Y18 [get_ports clk_50m]
# set_property PACKAGE_PIN W18 [get_ports rst_n]
# set_property PACKAGE_PIN AA19 [get_ports pwm_in]

# ===========================================================================
# 时序分析设置
# ===========================================================================

# 启用时序分析
set_timing_derate -early 0.95
set_timing_derate -late 1.05

# 时钟不确定性
set_clock_uncertainty -setup 0.100 [get_clocks clk_400m]
set_clock_uncertainty -hold 0.050 [get_clocks clk_400m]

# 输入抖动
set_input_jitter clk_50m 0.100
set_input_jitter clk_400m 0.050

# ===========================================================================
# 优化约束
# ===========================================================================

# 面积优化
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]

# 时序优化
set_property STRATEGY TIMING_DRIVEN [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# ===========================================================================
# 约束说明
# ===========================================================================

# 1. 时钟约束:
#    - 50MHz输入时钟: 20ns周期
#    - 400MHz输出时钟: 2.5ns周期
#    - 设置时钟组为异步，避免跨时钟域问题

# 2. 输入输出约束:
#    - PWM输入延迟: 考虑信号传输延迟
#    - 输出延迟: 确保数据稳定时间

# 3. 异步路径约束:
#    - PWM信号是异步输入，需要false path
#    - 复位信号也是异步的

# 4. 多周期路径:
#    - 同步器需要多个周期稳定
#    - 控制信号需要多个周期传播

# 5. 最大延迟约束:
#    - 关键路径设置最大延迟限制
#    - 确保400MHz时钟下满足时序

# 6. 物理约束:
#    - 时钟路由优化
#    - I/O标准定义
#    - 引脚位置分配

# ===========================================================================
# 使用时序约束检查命令
# ===========================================================================

# 在Vivado中运行以下命令检查约束:
# report_clocks
# report_clock_interaction
# report_timing_summary
# report_timing -max_paths 10
# report_exceptions

# ===========================================================================
# 约束调试建议
# ===========================================================================

# 1. 检查时钟定义是否正确:
#    report_clocks -verbose

# 2. 检查跨时钟域路径:
#    report_clock_interaction

# 3. 检查时序违规:
#    report_timing_summary -delay_type min_max

# 4. 检查false path约束:
#    report_exceptions -ignored

# 5. 检查多周期路径:
#    report_exceptions -setup
#    report_exceptions -hold

# ===========================================================================
# 性能预期
# ===========================================================================

# 时序目标:
# - 建立时间裕量: > 0.2ns
# - 保持时间裕量: > 0.1ns
# - 最大工作频率: 400MHz

# 资源目标 (方案一优化后):
# - LUT使用: < 1000
# - FF使用: < 800
# - CARRY4使用: ~18 (优化后，原为72)
# - MMCM使用: 1

# 功耗目标:
# - 静态功耗: < 100mW
# - 动态功耗: < 200mW @ 400MHz

# ===========================================================================