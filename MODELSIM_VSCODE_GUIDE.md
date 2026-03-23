# VSCode + ModelSim 联动配置指南

## 🎯 配置目标

在VSCode中编写Verilog代码，一键调用ModelSim进行仿真验证，提高开发效率。

## 📁 文件结构

```
rtl/
├── .vscode/                    # VSCode配置文件
│   ├── tasks.json             # 任务配置
│   ├── launch.json            # 调试配置
│   └── settings.json          # 编辑器设置
├── modelsim_setup/            # ModelSim配置
│   └── modelsim_config.tcl     # ModelSim TCL脚本
└── MODELSIM_VSCODE_GUIDE.md    # 本文件
```

## 🚀 快速开始

### 前提条件
1. 已安装ModelSim (10.7或更高版本)
2. 已安装VSCode
3. ModelSim已添加到系统PATH

### 配置步骤

#### 步骤1: 打开VSCode
```bash
code d:/01-Codes/XilinxCode/Vernier_tdc/rtl/
```

#### 步骤2: 验证配置
1. 按 `Ctrl+Shift+P` 打开命令面板
2. 输入 "Tasks: Configure Task" 确认tasks.json已加载
3. 检查底部状态栏是否显示Verilog语法高亮

## 🔧 使用方法

### 方法1: 使用VSCode任务 (推荐)

按 `Ctrl+Shift+P`，然后选择：

1. **"Tasks: Run Task"** → 选择以下任务之一：

   - 📝 **ModelSim: 编译TDC**
     - 仅编译所有TDC文件，快速检查语法
   - 🎯 **ModelSim: 运行10ps TDC仿真**
     - 运行10ps精度TDC的完整仿真测试
   - 🚀 **ModelSim: 运行进位链TDC仿真**
     - 运行进位链TDC仿真测试
   - 🖥️ **ModelSim: 打开GUI界面**
     - 打开ModelSim图形界面进行交互式调试
   - ⚡ **ModelSim: 测试特定时间间隔**
     - 测试指定的时间间隔（会提示输入ps值）

### 方法2: 使用快捷键

1. 按 `Ctrl+Shift+B` 打开任务选择器
2. 选择要运行的仿真任务

### 方法3: 使用终端命令

在VSCode集成终端中运行：
```bash
# 编译TDC
vsim -c -do "do modelsim_setup/modelsim_config.tcl; compile_tdc; quit"

# 运行10ps仿真
vsim -c -do "do modelsim_setup/modelsim_config.tcl; run_10ps_simulation; quit"

# 打开GUI
vsim -gui -do "do modelsim_setup/modelsim_config.tcl"
```

## 🎯 针对TDC的专用功能

### 快速测试不同精度

1. 按 `Ctrl+Shift+P`
2. 选择 "Tasks: Run Task"
3. 选择 "ModelSim: 测试特定时间间隔"
4. 输入要测试的时间值（如：10、50、100、500、1000）

### 波形查看

1. 运行 "ModelSim: 打开GUI界面"
2. 在ModelSim中会自动加载预定义的波形配置
3. 包括时钟、复位、TDC输入输出等关键信号

## 📊 仿真命令参考

### 在ModelSim中可用的命令：

```tcl
# 编译所有文件
compile_tdc

# 运行10ps TDC仿真
run_10ps_simulation

# 运行进位链TDC仿真
run_carry_chain_simulation

# 测试特定时间间隔（单位：ps）
test_specific_interval 100

# 显示帮助
help
```

## ⚙️ 配置详解

### tasks.json 配置
- **编译任务**: 快速检查语法错误
- **仿真任务**: 完整的测试流程
- **GUI任务**: 交互式调试
- **参数化任务**: 支持用户输入

### modelsim_config.tcl 功能
- 自动设置工程路径
- 智能库管理
- 预定义波形配置
- 专用TDC测试流程

## 🔍 调试技巧

### 1. 查看编译错误
- 编译失败时，错误信息会显示在VSCode终端
- 点击错误信息可直接跳转到问题代码

### 2. 波形分析
- 使用GUI模式打开ModelSim
- 波形已预配置好，包含关键信号
- 可以添加更多信号进行调试

### 3. 性能分析
- 10ps仿真会显示详细的精度测试结果
- 包括理论值、测量值和误差分析

## 🎯 针对你的TDC项目

### 推荐工作流程：

1. **编写代码**: 在VSCode中编辑 `v3_10ps_vernier_tdc/vernier_tdc_10ps.v`
2. **快速编译**: 运行 "ModelSim: 编译TDC" 检查语法
3. **功能验证**: 运行 "ModelSim: 运行10ps TDC仿真"
4. **精度测试**: 运行 "ModelSim: 测试特定时间间隔" 验证精度
5. **波形分析**: 运行 "ModelSim: 打开GUI界面" 查看详细波形

### 版本切换测试：

```bash
# 测试10ps版本
vsim -c -do "do modelsim_setup/modelsim_config.tcl; run_10ps_simulation; quit"

# 测试25ps版本
vsim -c -do "do modelsim_setup/modelsim_config.tcl; run_carry_chain_simulation; quit"
```

## ⚠️ 常见问题

### Q: ModelSim命令找不到
A: 确保ModelSim已添加到系统PATH，或手动指定完整路径

### Q: 编译错误
A: 检查Verilog语法，使用 "ModelSim: 编译TDC" 快速定位问题

### Q: 波形不显示
A: 使用GUI模式，确保添加了正确的信号到波形窗口

### Q: 仿真速度慢
A: 可以修改测试平台中的仿真时间，或使用 `-c` 模式运行命令行仿真

## 📞 需要帮助？

1. 查看ModelSim错误信息
2. 检查TCL脚本输出
3. 确认文件路径正确
4. 验证ModelSim版本兼容性

---

**配置状态**: ✅ 已完成
**适用项目**: TDC高精度时间数字转换器
**核心功能**: VSCode编写 + ModelSim仿真验证

现在你可以高效地在VSCode中开发TDC代码，一键调用ModelSim进行验证了！ 🎉