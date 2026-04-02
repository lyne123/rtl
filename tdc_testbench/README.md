# TDC测试激励信号生成器

## 项目概述

这是一个用于测试时间数字转换器（TDC）的激励信号生成模块。该模块能够生成具有随机占空比和混合随机相位的PWM信号，用于全面测试TDC的性能。

## 文件结构

```
tdc_testbench/
├── src/
│   ├── tdc_stimulus_generator.v        # 主要激励生成模块（完整版）
│   ├── tb_tdc_stimulus.v              # 测试平台（完整版）
│   ├── tdc_stimulus_generator_simple.v # 主要激励生成模块（简化版，Verilog兼容）
│   └── tb_tdc_stimulus_simple.v       # 测试平台（简化版，Verilog兼容）
└── README.md                          # 项目说明
```

## 功能特性

### 基本参数
- **主频**: 400MHz (2.5ns周期)
- **PWM基础周期**: 50ns (20个时钟周期)
- **占空比范围**: 5% ~ 95%
- **相位分辨率**: 625ps (1/4个时钟周期)

### 随机特性
1. **随机占空比**: 使用LFSR生成5%~95%之间的随机占空比
2. **粗相位延迟**: 在脉冲间随机插入0~7个整数时钟周期的延迟
3. **精相位抖动**: 使用四个相位时钟(0°, 90°, 180°, 270°)实现625ps步进的相位抖动

### 关键技术
- **LFSR随机数生成**: 32位线性反馈移位寄存器，多项式为x^32 + x^22 + x^2 + x^1 + 1
- **无毛刺相位切换**: 通过同步逻辑确保相位切换时无信号毛刺
- **安全参数更新**: 仅在PWM周期边界更新参数，避免中间状态

## 模块接口

### tdc_stimulus_generator

```verilog
module tdc_stimulus_generator (
    input wire clk_400m,           // 400MHz主时钟
    input wire clk_400m_0,         // 400MHz 0度相位
    input wire clk_400m_90,        // 400MHz 90度相位
    input wire clk_400m_180,       // 400MHz 180度相位
    input wire clk_400m_270,       // 400MHz 270度相位
    input wire rst_n,              // 低电平有效复位

    output reg pwm_out,            // PWM输出信号
    output reg [7:0] duty_cycle,   // 当前占空比（调试用）
    output reg [1:0] phase_sel     // 当前相位选择（调试用）
);
```

## 使用方法

### 版本选择

- **完整版** (`tdc_stimulus_generator.v`): 功能完整，但可能需要SystemVerilog支持
- **简化版** (`tdc_stimulus_generator_simple.v`): 标准Verilog兼容，推荐用于Vivado仿真

### 1. 集成到现有TDC测试

```verilog
// 实例化激励生成器（推荐使用简化版）
tdc_stimulus_generator_simple stimulus_gen (
    .clk_400m(sys_clk_400m),
    .clk_400m_0(clk_0_deg),
    .clk_400m_90(clk_90_deg),
    .clk_400m_180(clk_180_deg),
    .clk_400m_270(clk_270_deg),
    .rst_n(reset_n),
    .pwm_out(tdc_input_signal)
);

// 连接到TDC模块
fine_counter_carry4 tdc_inst (
    .clk_400m(sys_clk_400m),
    .rst_n(reset_n),
    .pwm_signal(tdc_input_signal),
    .fine_count_a(fine_count_a),
    .fine_count_b(fine_count_b),
    .valid_out(valid_out)
);
```

### 2. 运行测试平台

#### 简化版（推荐）
```bash
# 使用XSIM (Vivado)
xvlog tdc_stimulus_generator_simple.v tb_tdc_stimulus_simple.v
xelab tb_tdc_stimulus_simple
xsim tb_tdc_stimulus_simple

# 使用ModelSim/QuestaSim
vlog tdc_stimulus_generator_simple.v tb_tdc_stimulus_simple.v
vsim tb_tdc_stimulus_simple
run -all
```

#### 完整版
```bash
# 可能需要SystemVerilog模式
xvlog -sv tdc_stimulus_generator.v tb_tdc_stimulus.v
xelab tb_tdc_stimulus
xsim tb_tdc_stimulus
```

## 测试验证

### 验证项目
1. **PWM周期正确性**: 确保基础周期为50ns
2. **占空比范围**: 验证占空比在5%~95%范围内
3. **相位切换**: 检查相位切换时无毛刺
4. **随机性**: 确认输出信号的随机特性

### 预期输出特性
- PWM信号周期：50ns ± 粗相位延迟
- 占空比：5%~95%随机变化
- 相位抖动：625ps步进
- 无毛刺切换

## 设计考虑

### 时序约束
```tcl
# 主时钟
create_clock -period 2.5 [get_ports clk_400m]

# 相位时钟（由MMCM生成，需要适当约束）
create_generated_clock -name clk_0 -source [get_pins mmcm_inst/CLKOUT0] [get_ports clk_400m_0]
create_generated_clock -name clk_90 -source [get_pins mmcm_inst/CLKOUT1] [get_ports clk_400m_90]
# ... 其他相位时钟
```

### 综合注意事项
- LFSR模块会被综合为移位寄存器
- 相位多路复用器需要时序约束
- 同步器用于跨时钟域信号

## 扩展建议

1. **增加配置接口**: 添加寄存器接口配置参数范围
2. **添加触发输出**: 提供同步触发信号供示波器使用
3. **增加统计功能**: 输出随机数分布统计
4. **支持更多相位**: 扩展到8相位或更高分辨率

## 故障排除

### 常见问题
1. **PWM信号不稳定**: 检查时钟相位关系是否正确
2. **占空比超出范围**: 验证LFSR随机数生成逻辑
3. **相位切换有毛刺**: 检查同步器是否正常工作
4. **仿真时间过长**: 调整测试平台的仿真时间

### 调试建议
- 使用`duty_cycle`和`phase_sel`输出监控内部状态
- 添加ILA核捕获关键信号
- 分阶段验证：先验证基本功能，再验证随机特性

## 性能参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 主时钟频率 | 400MHz | 2.5ns周期 |
| PWM基础周期 | 50ns | 20个时钟周期 |
| 占空比分辨率 | 5% | 1/20 |
| 精相位步进 | 625ps | 1/4时钟周期 |
| 粗相位步进 | 2.5ns | 1个时钟周期 |
| LFSR周期 | 2^32-1 | 最大长度序列 |

---

*创建时间: 2026年4月1日*
*版本: 1.0*
