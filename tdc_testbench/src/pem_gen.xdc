set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pwm_signal_IBUF]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports sys_rst_n]

set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports pwm_out]

# 【关键】将压摆率设为 FAST，保证边缘足够陡峭
set_property SLEW FAST [get_ports pwm_out]
# 也可以考虑增加驱动电流，例如 12mA 或 16mA
set_property DRIVE 16 [get_ports pwm_out]