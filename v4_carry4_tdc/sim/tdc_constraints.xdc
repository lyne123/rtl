# ============================================================================
# TDC 设计约束文件（简化版本）
# ============================================================================

# 1. 基本时钟约束
create_clock -period 20.000 -name clk_50m [get_ports clk_50m]

# 2. 400MHz时钟约束（用于实现，仿真中可能不需要）
create_generated_clock -name clk_400m \
    -source [get_clocks clk_50m] \
    -multiply_by 8 \
    [get_ports clk_400m]

# 3. 时钟不确定性
set_clock_uncertainty -setup 0.100 [get_clocks clk_400m]
set_clock_uncertainty -hold 0.050 [get_clocks clk_400m]

# 4. 异步时钟组
set_clock_groups -asynchronous \
    -group [get_clocks clk_50m] \
    -group [get_clocks clk_400m]

# 5. PWM输入约束
set_input_delay -clock clk_400m -max 1.0 [get_ports pwm_in]
set_input_delay -clock clk_400m -min 0.5 [get_ports pwm_in]

# 6. 输出约束
set_output_delay -clock clk_400m -max 2.0 [get_ports time_interval*]
set_output_delay -clock clk_400m -max 2.0 [get_ports valid]
set_output_delay -clock clk_400m -max 2.0 [get_ports measurement_error]

# 7. 多周期路径约束
set_multicycle_path 2 -setup -from [get_clocks clk_400m] -to [get_clocks clk_400m]
set_multicycle_path 1 -hold -from [get_clocks clk_400m] -to [get_clocks clk_400m]

# 8. 最大延迟约束
set_max_delay 10.0 -from [get_ports pwm_in] -to [get_ports time_interval*]

# 9. CARRY4布局约束
set_property BEL CARRY4 [get_cells -hierarchical -filter {REF_NAME == CARRY4}]
set_property LOCK_PINS {A0:A A1:B A2:C A3:D B0:B1 B1:B2 B2:B3 B3:CY} \
    [get_cells -hierarchical -filter {REF_NAME == CARRY4}]