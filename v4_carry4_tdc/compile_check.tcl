# 简单的编译检查脚本
puts "开始编译检查..."

# 检查测试平台文件
if {[catch {read_verilog ../sim/tb_carry4_tdc.v} err]} {
    puts "ERROR: 测试平台编译失败"
    puts $err
} else {
    puts "测试平台编译成功"
}

# 检查顶层模块
if {[catch {read_verilog ../src/tdc_top_carry4.v} err]} {
    puts "ERROR: 顶层模块编译失败"
    puts $err
} else {
    puts "顶层模块编译成功"
}

puts "编译检查完成"