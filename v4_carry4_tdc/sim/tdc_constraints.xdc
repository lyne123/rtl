# ============================================================================
# TDC 设计约束文件
# ============================================================================

# 创建时钟
create_clock -period 20.000 -name clk_50m [get_ports clk_50m]

# 生成时钟 (400MHz)
create_generated_clock -name clk_400m \
    -source [get_pins uut/u_mmcm/clk_in_50m] \
    -multiply_by 8 \
    [get_pins uut/u_mmcm/clk_out_400m]

# 设置异步时钟组
set_clock_groups -asynchronous \
    -group [get_clocks clk_50m] \
    -group [get_clocks clk_400m]

# PWM输入延迟约束
set_input_delay -clock clk_400m -max 1.0 [get_ports pwm_in]
set_input_delay -clock clk_400m -min 0.5 [get_ports pwm_in]

# 输出延迟约束
set_output_delay -clock clk_400m -max 2.0 [get_ports time_interval*]
set_output_delay -clock clk_400m -max 2.0 [get_ports valid]
set_output_delay -clock clk_400m -max 2.0 [get_ports measurement_error]

# 多周期路径约束（三级采样）
set_multicycle_path 3 -setup -from [get_clocks clk_400m] -to [get_clocks clk_400m]
set_multicycle_path 2 -hold -from [get_clocks clk_400m] -to [get_clocks clk_400m]

# CARRY4延迟链false path
set_false_path -through [get_pins uut/u_tdc_a/carry_chain*]
set_false_path -through [get_pins uut/u_tdc_b/carry_chain*]

# 最大延迟约束
set_max_delay 10.0 -from [get_ports pwm_in] -to [get_ports time_interval*]

# CARRY4布局约束
set_property BEL CARRY4 [get_cells -hierarchical -filter {REF_NAME == CARRY4}]
set_property LOCK_PINS {A0:A A1:B A2:C A3:D B0:B1 B1:B2 B2:B3 B3:CY} \
    [get_cells -hierarchical -filter {REF_NAME == CARRY4}]