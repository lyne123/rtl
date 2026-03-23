# 版本4: 项目文档管理

## 📋 文件说明

- **VERSION_CONTROL.md** - 版本管理指南
- **README_USAGE.md** - 快速使用说明
- **PROJECT_STRUCTURE.txt** - 项目结构总览

## 📚 文档用途

### VERSION_CONTROL.md
- 详细的版本对比和演进历史
- 各版本特性说明
- 文件组织结构

### README_USAGE.md
- 快速上手指南
- 三步开始使用
- 常见问题解答

### PROJECT_STRUCTURE.txt
- 完整的项目文件结构
- 推荐文件组合
- 性能对比总结

## 🎯 使用建议

1. **新手入门**: 先阅读 `README_USAGE.md`
2. **版本选择**: 参考 `VERSION_CONTROL.md`
3. **项目管理**: 使用 `PROJECT_STRUCTURE.txt`

## 📁 完整项目结构

```
Vernier_tdc/rtl/
├── v1_original_design/          # 原始游标TDC
│   ├── original_vernier_tdc.v
│   ├── original_tdc_alignment.v
│   └── README_v1.md
│
├── v2_carry_chain_tdc/          # 进位链TDC (25ps)
│   ├── tdc_top.v
│   ├── tb_tdc_top.v
│   ├── tdc_analysis.txt
│   └── README_v2.md
│
├── v3_10ps_vernier_tdc/         # 10ps游标TDC ⭐推荐
│   ├── vernier_tdc_10ps.v
│   ├── tb_10ps_test.v
│   ├── 10ps_design_spec.txt
│   └── README_v3.md
│
└── v4_documentation/            # 项目文档
    ├── VERSION_CONTROL.md
    ├── README_USAGE.md
    ├── PROJECT_STRUCTURE.txt
    └── README_v4.md
```

## 🚀 推荐使用流程

1. **了解项目**: 阅读 `v4_documentation/README_USAGE.md`
2. **选择版本**: 参考 `v4_documentation/VERSION_CONTROL.md`
3. **开始使用**:
   - 高精度需求 → 使用 `v3_10ps_vernier_tdc/`
   - 一般需求 → 使用 `v2_carry_chain_tdc/`
   - 学习原理 → 参考 `v1_original_design/`
4. **深入理解**: 阅读对应版本的README和规格书
5. **验证测试**: 运行测试平台验证功能

## 📊 版本演进路线

```
v1_original_design (2ns, 不可综合)
    ↓
v2_carry_chain_tdc (25ps, 可综合, +80x精度)
    ↓
v3_10ps_vernier_tdc (10ps, 可综合, +200x精度)
    ↓
你的高精度TDC应用 🚀
```

## 💡 快速决策指南

### 你需要10ps精度?
✅ 使用 `v3_10ps_vernier_tdc/vernier_tdc_10ps.v`

### 你需要平衡性能和复杂度?
✅ 使用 `v2_carry_chain_tdc/tdc_top.v`

### 你想学习TDC原理?
✅ 研究 `v1_original_design/` 中的设计

### 你不知道如何选择?
✅ 阅读 `v4_documentation/README_USAGE.md`

---

**项目状态**: 完整，可直接使用
**最后更新**: 2026-03-18
**推荐版本**: v3_10ps_vernier_tdc
**适用器件**: xc7a100tfgg484-2
**开发工具**: Vivado