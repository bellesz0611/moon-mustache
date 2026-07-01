# Moon Mustache

Moon Mustache is a Mustache template engine implementation for MoonBit.

Moon Mustache 是一个面向 MoonBit 生态的 Mustache 模板引擎实现，目标是提供轻量、稳定、可复用的模板渲染基础能力，服务于脚手架生成、配置文件渲染、静态内容拼装、邮件模板和消息正文生成等场景。

## Why this project

MoonBit already has a strong language core and toolchain, but reusable template
rendering is still a missing piece in the ecosystem. Many practical tools need
to turn structured data into text output:

- project scaffolding
- configuration generation
- static content rendering
- email and notification templates
- code generation helpers

This project focuses on a small, stable, reusable core instead of building a
feature-heavy template language.

## 目前要解决的问题

MoonBit 生态当前已经具备不错的语言设计和统一工具链，但在很多项目会反复遇到的通用基础能力上仍然有补齐空间。模板渲染正是其中很典型的一类需求：

- 工程脚手架生成时需要把变量填入模板文件
- 配置生成工具需要把结构化数据转成文本
- 文档、静态页面和提示词片段需要批量渲染
- 邮件、通知和消息正文通常需要统一模板层

Moon Mustache 计划优先把这些场景需要的核心能力做扎实，而不是扩展成一个功能过重、边界不清的大模板语言。

## Stage-one scope

The first milestone focuses on:

- repository and module scaffolding
- parser and renderer architecture
- core Mustache syntax coverage planning
- early examples and compatibility notes
- test layout for spec-driven development

## 当前阶段交付

当前仓库处于第一阶段启动状态，已经完成：

- 仓库初始化与许可证配置
- MoonBit 模块与包配置骨架
- token / AST / scanner / parser / renderer 的初始结构
- 早期测试入口
- CLI 占位入口和示例文档
- 项目申报材料、架构说明和路线图

后续会继续补齐扫描器、解析器、上下文查找、Partial 支持、文件接口和规范兼容测试。

## Planned features

- tokenization and parsing for Mustache templates
- AST-based rendering pipeline
- context stack and dotted path lookup
- sections, inverted sections, comments, partials, and delimiter changes
- escaped and unescaped value rendering
- file-oriented rendering helpers
- a small CLI for local template rendering

## Planned public API

The project is currently planned around a small public surface:

- `parse_template`
- `render_string`
- `render_file`
- a CLI entry point for local rendering

The intent is to keep the API small and predictable so it can be embedded into
other MoonBit tools without dragging in unnecessary complexity.

## Repository layout

- `src/`: library source files
- `cli/`: command-line entry point
- `examples/`: usage snippets and sample flows
- `docs/`: proposal, design, and roadmap notes
- `.github/workflows/`: CI configuration

## Development plan

Near-term work is planned in roughly this order:

1. improve the scanner so it can split plain text and tag segments correctly
2. flesh out parser branches for sections, comments, partials, and delimiter changes
3. stabilize the context lookup model and rendering behavior
4. add more spec-aligned tests and examples
5. wire file-based rendering helpers and improve the CLI
6. prepare for mooncakes.io publishing once the package API is stable

## CI status

The repository includes a bootstrap CI workflow intended to run basic checks
and tests once the MoonBit toolchain is available in the CI environment.

## Reference projects

- [mustache.js](https://github.com/janl/mustache.js)
- [mustache/spec](https://github.com/mustache/spec)

## Repository status

This repository is in active bootstrap. Early commits focus on project
structure, design notes, and minimal MoonBit code skeletons that will be
expanded into a reusable library.
