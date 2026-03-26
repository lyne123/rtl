# TDC v5 直接采样架构

## 🎯 项目概述

TDC v5是一个基于FPGA的高精度时间数字转换器，采用创新的**直接延迟链采样**架构，专门设计用于测量0-50ns范围内的脉冲宽度，理论分辨率达到35ps。

### 🌟 核心特性

- **全范围测量**: 0-50ns无缝覆盖
- **超高精度**: 35ps理论分辨率
- **无脉宽限制**: 可测量任意窄的脉冲
- **高可靠性**: 多级错误检测和防护
- **模块化设计**: 易于扩展和维护

## 📁 项目结构

```
v5_direct_sampling_tdc/
├── src/                    # 源代码
│   ├── tdc_top_v5.v       # 顶层模块
│   ├── pwm_delay_chain_sampler.v    # 延迟链采样模块
│   ├── coarse_counter_pwm.v         # 粗计数器模块
│   ├── thermometer_decoder_72to7.v  # 温度计码解码器
│   └── pwm_data_fusion.v           # 数据融合模块
├── sim/                    # 仿真文件
│   └── tb_tdc_v5.v        # 测试平台
├── doc/                    # 文档
│   └── v5_architecture_overview.md  # 架构设计文档
└── README.md              # 本文件
```

## 🚀 快速开始

### 环境要求

- **FPGA开发工具**: Xilinx Vivado 2020.2或更高版本
- **目标器件**: xc7a100tfgg484-2 (Artix-7系列)
- **仿真工具**: ModelSim, Vivado Simulator或其他Verilog仿真器

### 文件编译顺序

```tcl
# 1. 编译源文件
vlog -work work +incdir+../src/ \
    pwm_delay_chain_sampler.v \
    coarse_counter_pwm.v \
    thermometer_decoder_72to7.v \
    pwm_data_fusion.v \
    tdc_top_v5.v

# 2. 编译测试平台
vlog -work work +incdir+../sim/ \
    tb_tdc_v5.v

# 3. 运行仿真
vsim work.tb_tdc_v5
run -all
```

### 基本使用

```verilog
// TDC模块实例化
tdc_top_v5 u_tdc (
    .clk_50m(clk_50m),           // 50MHz系统时钟
    .rst_n(rst_n),               // 异步复位(低电平有效)
    .pwm_in(pwm_in),             // PWM信号输入
    .time_interval(time_interval), // 时间间隔输出(皮秒)
    .valid(valid),               // 测量有效信号
    .measurement_error(error)    // 测量错误指示
);
```

## 📊 性能指标

### 测量性能

| 参数 | 数值 | 说明 |
|------|------|------|
| **测量范围** | 0-50ns | 全范围覆盖 |
| **理论分辨率** | 35ps | CARRY4单级延迟 |
| **实际精度** | 50-100ps | 考虑工艺变化 |
| **最大误差** | ±200ps | 设计目标值 |

### 时序性能

| 参数 | 数值 | 说明 |
|------|------|------|
| **系统时钟** | 400MHz | MMCM生成 |
| **采样延迟** | 7.5ns | 三级同步延迟 |
| **总延迟** | ~10ns | 从输入到输出 |

### 资源消耗

| 资源类型 | 数量 | 占用率(xc7a100t) |
|----------|------|------------------|
| **CARRY4** | 18个 | ~5% |
| **触发器** | ~200个 | ~1% |
| **LUT** | ~300个 | ~2% |
| **MMCM** | 1个 | 1个 |

## 🔧 设计原理

### 测量方法

TDC v5采用**直接延迟链采样**技术，突破传统边沿检测的限制：

1. **短脉宽测量** (0-2.5ns):
   ```
   测量值 = 温度计码中1的个数 × 35ps
   ```

2. **长脉宽测量** (2.5ns-50ns):
   ```
   测量值 = 粗计数值 × 2500ps + 细计数值 × 35ps
   ```

### 系统架构

```
PWM输入 → 延迟链采样 → 温度计码解码 → 数据融合 → 时间间隔输出
            ↓
        粗计数器 → 数据融合
            ↓
        系统时钟(400MHz)
```

## 📝 测试验证

### 测试平台功能

- **全范围测试**: 100ps-50ns脉宽测试
- **边界测试**: 最小/最大脉宽测试
- **连续测试**: 脉冲序列测试
- **随机测试**: 随机脉宽测试
- **性能分析**: 精度和误差统计

### 预期测试结果

| 测试项目 | 预期结果 |
|----------|----------|
| **精度测试** | 误差<200ps，通过率>95% |
| **范围测试** | 0-50ns全覆盖 |
| **稳定性测试** | 连续运行1小时无异常 |

## 🎯 应用场景

### 主要应用领域

1. **激光测距**
   - 高精度距离测量
   - 激光脉冲飞行时间测量

2. **粒子物理实验**
   - 粒子飞行时间测量
   - 超短脉冲检测

3. **高速通信**
   - 精确时序分析
   - 时钟恢复

4. **雷达系统**
   - 高精度距离测量
   - 脉冲宽度分析

## ⚙️ 设计约束

### 时序约束

```tcl
# 延迟链关键约束
set_property DONT_TOUCH true [get_cells pwm_delay_chain_sampler*]
set_false_path -from [get_ports pwm_in] -to [get_registers pwm_thermometer*]

# 粗计数器约束
set_max_delay 2.5 -from [get_registers counter*] -to [get_registers pulse_width_coarse*]
```

### 物理约束

```tcl
# CARRY4布局约束
set_property BEL CARRY4 [get_cells -hierarchical -filter {REF_NAME == CARRY4}]
set_property LOC SLICE_X0Y0 [get_cells pwm_delay_chain_gen[0].carry4_inst]
```

## 🔄 版本历史

### v5.0 (当前版本)
- **新增**: 直接延迟链采样架构
- **改进**: 支持0-50ns全范围测量
- **优化**: 35ps理论分辨率
- **修复**: 消除最小脉宽限制

## 📚 相关文档

- [架构设计文档](doc/v5_architecture_overview.md) - 详细的设计原理和实现说明
- [测试平台代码](sim/tb_tdc_v5.v) - 完整的测试验证代码
- [源代码注释](src/) - 详细的代码注释和说明

## 🤝 贡献指南

欢迎对TDC v5设计提出改进建议或贡献代码。请遵循以下步骤：

1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/new-feature`)
3. 提交更改 (`git commit -am 'Add new feature'`)
4. 推送分支 (`git push origin feature/new-feature`)
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证。详见 [LICENSE](LICENSE) 文件。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交Issue
- 发送邮件
- 在讨论区留言

---

**TDC v5 - 突破传统限制，实现ps级时间测量精度** 🎯