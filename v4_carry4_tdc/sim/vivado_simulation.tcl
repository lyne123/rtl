# ============================================================================
# Vivado TDC 仿真脚本
# 功能: 创建Vivado项目并运行TDC仿真
# ============================================================================

# 设置变量
set project_name "tdc_carry4_sim"
set project_dir "D:/01-Codes/XilinxCode/Vernier_tdc/rtl/v4_carry4_tdc/sim/vivado_project"
set rtl_dir "D:/01-Codes/XilinxCode/Vernier_tdc/rtl"
set device "xc7a100tfgg484-2"

# 创建项目
create_project $project_name $project_dir -part $device

# 设置项目属性
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

# 添加RTL源文件
add_files -norecurse {
    $rtl_dir/v4_carry4_tdc/src/tdc_top_carry4.v
    $rtl_dir/v4_carry4_tdc/src/carry4_delay_chain.v
    $rtl_dir/v4_carry4_tdc/src/coarse_counter_400m.v
    $rtl_dir/v4_carry4_tdc/src/edge_detector_sync.v
    $rtl_dir/v4_carry4_tdc/src/thermometer_decoder.v
    $rtl_dir/v4_carry4_tdc/src/timestamp_synthesizer_dual.v
    $rtl_dir/v4_carry4_tdc/src/clock_reference_gen.v
    $rtl_dir/v4_carry4_tdc/src/mmcm_50m_to_400m.v
}

# 添加测试平台文件
add_files -fileset sim_1 -norecurse {
    $rtl_dir/v4_carry4_tdc/src/tb_carry4_tdc.v
}

# 更新编译顺序
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 设置顶层模块
set_property top tb_carry4_tdc [get_filesets sim_1]

# 运行行为仿真
launch_simulation

# 添加波形
add_wave /tb_carry4_tdc/*
add_wave /tb_carry4_tdc/uut/*

# 运行仿真
run 10000 ns

# 保存波形配置
save_wave_config $project_dir/${project_name}.wcfg

puts "=========================================="
puts "Vivado TDC仿真设置完成!"
puts "项目位置: $project_dir"
puts "可以手动运行更长时间的仿真"
puts "=========================================="