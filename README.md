# MoonBit 海洋生物地球化学箱式模型引擎 (`moonbit-biogeochem`)

> **MoonBit 2026 开源创新大赛 (OSC 2026) 参赛项目**

`moonbit-biogeochem` 是基于 MoonBit 原生语言开发的高性能、高扩展海洋生物地球化学箱式模型引擎（Marine Biogeochemical Box Model Engine）。

## 🌟 核心特性
- **可组合生态模块**：内置 NPZD、NPZD+D、氧亏损（DO/BOD）与海洋碳酸盐系统化学（DIC, TA, pCO₂）。
- **多种数值求解器**：提供 Euler、经典 RK4 以及 RKF45 (Dormand-Prince) 自适应步长积分器。
- **质量守恒与量纲安全**：具备 Redfield 配比审计、元素质量守恒检测与物理量纲缩放。
- **分析与导出工具**：支持参数网格扫描、敏感性分析、JSON/CSV 数据导出及终端 ASCII 视效渲染。

## 📄 开源许可
Apache License 2.0
