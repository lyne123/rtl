# 🎯 VSCode + ModelSim 快速参考

## 📋 一句话总结

**在VSCode中编写TDC代码 → 一键调用ModelSim仿真验证**

## 🚀 三步快速开始

### 步骤1: 打开VSCode
```bash
# 打开TDC工程目录
code d:/01-Codes/XilinxCode/Vernier_tdc/rtl/
```

### 步骤2: 运行仿真 (两种方式)

**方式A: 使用快捷键**
- 按 `Ctrl+Shift+P`
- 输入 "Tasks: Run Task"
- 选择仿真任务

**方式B: 使用命令面板**
- 按 `Ctrl+Shift+B`
- 选择任务

### 步骤3: 查看结果
- 终端显示仿真结果
- 或使用GUI模式查看波形

## 🎯 常用任务

| 任务名称 | 快捷键 | 用途 |
|---------|--------|------|
| 编译TDC | Ctrl+Shift+P → "编译TDC" | 检查语法 |
| 10ps仿真 | Ctrl+Shift+P → "10ps TDC仿真" | 完整测试 |
| 打开GUI | Ctrl+Shift+P → "打开GUI界面" | 波形分析 |
| 特定测试 | Ctrl+Shift+P → "特定时间间隔" | 精度验证 |

## ⚡ 快速命令

```bash
# 编译检查
vsim -c -do "do modelsim_setup/modelsim_config.tcl; compile_tdc; quit"

# 10ps仿真
vsim -c -do "do modelsim_setup/modelsim_config.tcl; run_10ps_simulation; quit"

# 打开GUI
vsim -gui -do "do modelsim_setup/modelsim_config.tcl"
```

## 🎯 针对TDC的专用操作

### 测试不同精度
1. Ctrl+Shift+P
2. 选择 "测试特定时间间隔"
3. 输入数值：10 (测试10ps)

### 版本对比测试
- **10ps版本**: 选择 "10ps TDC仿真"
- **25ps版本**: 选择 "进位链TDC仿真"

## 📊 预期输出

### 10ps仿真结果示例
```
测试 100 ps 时间间隔:
预期: 100 ps
测量: 105.2 ps
误差: 5.2 ps
✓ 10ps精度测试通过
```

## 🎨 VSCode界面提示

- ✅ Verilog语法高亮
- ✅ 代码自动完成
- ✅ 错误实时提示
- ✅ 一键仿真验证

## ⚠️ 常见问题

**Q: ModelSim打不开？**
A: 检查ModelSim是否添加到PATH

**Q: 编译错误？**
A: 运行 "编译TDC" 任务查看详细错误

**Q: 波形不显示？**
A: 使用GUI模式，信号已预配置

## 📚 详细文档

- `MODELSIM_VSCODE_GUIDE.md` - 完整配置指南
- `v4_documentation/README_USAGE.md` - TDC使用说明
- `v3_10ps_vernier_tdc/README_v3.md` - 10ps TDC详细说明

---

**核心文件**: `v3_10ps_vernier_tdc/vernier_tdc_10ps.v`
**配置状态**: ✅ 已完成
**目标精度**: 10ps ✅

🎯 **现在开始你的高效TDC开发之旅！**