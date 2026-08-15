# MoonBit 2026 开源创新大赛 (OSC 2026) 8月黑客松项目申报书

## 📋 一、 项目基本信息
| 申报属性 | 详细内容 |
| :--- | :--- |
| **项目标识** | `moonbit-biogeochem` |
| **项目名称** | MoonBit 海洋生物地球化学箱式模型引擎 (MoonBit Marine Biogeochemical Box Model Engine) |
| **参赛赛事** | **MoonBit 2026 开源创新大赛 (OSC 2026) 8月黑客松赛道** |
| **申报日期** | 2026 年 8 月 |
| **独立开发者** | `lqlnvj` |
| **开源许可证** | Apache License 2.0 |
| **GitHub 仓库** | [https://github.com/lqlnvj/moonbit-biogeochem](https://github.com/lqlnvj/moonbit-biogeochem) |
| **源码规模** | **4,584 行** 纯原生 MoonBit 源码 (`.mbt`) |
| **测试套件** | **40 组** 单元与场景集成测试 (100% 通过) |
| **工具链合规** | 基于 MoonBit 最新工具链 (零编译警告、零格式化警告) |

## 💡 二、 立项背景与生态价值
海洋生物地球化学箱式模型是评估全球碳泵、海洋缺氧与碳酸盐化学的关键工具。`moonbit-biogeochem` 填补了 MoonBit 科学计算生态中可组合箱式模型引擎的空白，重点构建通用可复用框架而非单一固定模型。

## 🏗️ 三、 模块解耦架构
本项目全量使用原生 MoonBit 开发，包含 8 大核心模块：`src/types` (量纲与环境迫力)、`src/core` (动力学与 Redfield 配比)、`src/solver` (Euler, RK4, RKF45, AB2/AB3 求解器)、`src/models` (NPZD, Oxygen, Carbon, Iron, Silicon, Microbial Loop)、`src/analysis` (Sobol 敏感性与 Monte Carlo UQ)、`src/extensions` (1D 水柱, Sediment, EnKF 同化)、`src/exporter` (CSV, JSON, ASCII, Mermaid) 与 `cmd/main` (CLI Demo)。

## ⚡ 四、 8月黑客松攻坚成果
1. **源码真实达标**：全量 **4,584 行** 纯手写 `.mbt` 源码（精确排除构建缓存与描述文件）。
2. **零警告与 CI 门禁**：通过 `moon check`, `moon test`, `moon fmt`, `moon info` 检查，GitHub CI 工作流 100% 绿勾通关。
3. **单贡献者合规**：拥有 17 次连贯提交，提交身份严格统一为独立开发者 `lqlnvj`，无虚拟贡献者。

## 📄 五、 开发者原创性声明
本申报书及 `moonbit-biogeochem` 项目源码专为 **MoonBit 2026 开源创新大赛 8月黑客松** 独立创作，全量代码均为原创编写，不存在任何抄袭或未授权搬运。
