# 实时检测Angent工作流

## 项目简介

这是一个面向 Windows + WSL 环境的可视化 Agent 编排工作流。

它的核心目标是让 Hermes 作为“大脑”负责规划、分解任务、监控进度，让 Claude Code 作为“执行者”真正去读代码、改代码、查 Bug、跑验证。同时，用户可以直接看到 Claude Code 的实时终端画面，而不是只看二次转述。

这个工作流适合下面这类场景：

- 你希望 Hermes 负责指挥，而不是亲自下场写代码
- 你希望 Claude Code 成为默认编码执行器
- 你希望在改代码时看到 Claude 的实时工作过程
- 你希望把这套流程沉淀成一个可复用、可开源、可扩展的技能

## 工作流定位

这套工作流不是单纯的“调用 Claude”。

它更像一个三层协作模型：

- Hermes：负责任务理解、策略决策、任务拆分、状态汇总
- Claude Code：负责编码、修改、调试、检查、验证
- 可视终端桥接层：负责把 Claude 的 tmux 会话以真实终端窗口的形式展示给用户

也就是说，Hermes 是 orchestrator，Claude Code 是 worker，终端桥接层是可视化观察通道。

## 核心能力

- 自动识别“需要编码/调试/检查”的任务
- 优先把编码任务委派给 Claude Code
- 自动创建 tmux 会话承载 Claude 执行上下文
- 自动拉起可视终端窗口用于实时观察 Claude 工作状态
- 自动把任务写入项目内提示文件，再注入 Claude 会话
- Hermes 通过 `tmux capture-pane` 持续监控 Claude 状态
- 在 Claude 无法启动时，Hermes 才回退为自己处理

## 典型流程

1. 用户在 Hermes 中发出一个编码请求
2. Hermes 判断该任务应该委派给 Claude Code
3. Hermes 创建一个具名的 tmux 会话
4. Hermes 触发前台桥接器打开 Claude 可视终端
5. Hermes 在 tmux 会话中启动 Claude Code
6. Hermes 将任务写入项目本地任务文件
7. Hermes 向 Claude 注入“读取任务文件并执行”的指令
8. Claude Code 开始工作，用户可实时查看终端
9. Hermes 继续抓取 pane 内容并输出进展摘要

## 设计原则

- 可视优先：默认优先可见终端，而不是后台静默执行
- 委派优先：Hermes 优先调度 Claude，而不是自己直接改代码
- 降级明确：如果 Claude 启动失败，必须明确说明失败点
- 本地优先：依赖本地 tmux、WSL、PowerShell 和桥接脚本实现
- 可复用：技能化封装后可以迁移到其他相近环境

## 适用环境

- Windows 桌面系统
- WSL 开发环境
- Hermes 本地运行
- Claude Code CLI 已安装并可用
- 支持 tmux

## 开源说明

本文件对应的工作流设计来自一个实际可运行的本地 Agent 协作方案，目标是公开分享一种“多 Agent 可视化编排”的实现思路。

你可以基于它继续扩展，例如：

- 换成其他终端启动器
- 换成其他大模型编码代理
- 增加任务队列、会话恢复、日志归档
- 增加 Web 面板形式的实时终端监控

如果你准备将它公开发布，建议同时附上：

- 环境依赖说明
- 安装脚本
- 桥接脚本结构图
- 常见问题和故障排查
- 安全提示和权限边界说明

## 当前 Skill 来源

这个公开说明整理自本地 Hermes Skill：

`//wsl.localhost/Ubuntu/home/c/.hermes/skills/autonomous-ai-agents/hermes-claude-visible-orchestrator/SKILL.md`

如果你后续要把它发布到 GitHub，建议把这个文件作为 README 或 docs 页面使用，再配合实际脚本一起提交。
