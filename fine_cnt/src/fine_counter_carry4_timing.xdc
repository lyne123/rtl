# Fine Counter CARRY4 Delay Chain Timing Constraints
# 保护CARRY4延迟链不被优化

# 防止CARRY4链被优化
dont_touch rising_delay_chain[*].carry4_rising_inst
dont_touch falling_delay_chain[*].carry4_falling_inst

# 设置延迟链为false path，因为不是同步时序路径
set_false_path -from [get_pins rising_delay_chain[0].carry4_rising_inst/CYINIT] -to [get_pins rising_delay_chain[19].carry4_rising_inst/CO]
set_false_path -from [get_pins falling_delay_chain[0].carry4_falling_inst/CYINIT] -to [get_pins falling_delay_chain[19].carry4_falling_inst/CO]

# 设置延迟链的输入为异步路径
set_false_path -from [get_ports pwm_signal]

# 保护延迟链信号不被优化
set_property DONT_TOUCH true [get_nets {carry_chain_a[*]}]
set_property DONT_TOUCH true [get_nets {carry_chain_b[*]}]
set_property DONT_TOUCH true [get_nets {delay_chain_a[*]}]
set_property DONT_TOUCH true [get_nets {delay_chain_b[*]}]

# 设置采样路径的多周期约束
set_multicycle_path 2 -setup -from [get_pins rising_delay_chain[*].carry4_rising_inst/O[*]] -to [get_pins sampled_chain_a_reg[*]/D]
set_multicycle_path 2 -setup -from [get_pins falling_delay_chain[*].carry4_falling_inst/O[*]] -to [get_pins sampled_chain_b_reg[*]/D]