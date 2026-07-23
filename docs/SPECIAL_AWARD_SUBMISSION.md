# 专项鼓励奖一页申报稿

## 申报方向

主申报：**最佳测试**。辅申报：**最佳文档**。AI 协作仅作为可审计的工程过程证据，不作为主要获奖主张。

## 项目一句话

Moon Mustache 是 MoonBit 原生 Mustache 模板引擎与安全多文件生成器，把结构化数据可靠地转换为配置、文档、通知和项目骨架，并用可复现测试证据证明跨规范、跨实现、跨编译后端和 CLI 边界的一致性。

## 为什么值得“最佳测试”

项目不是依靠单一测试数量，而是用互补证据覆盖不同风险：

| 风险 | 可审计证据 |
| --- | --- |
| 核心实现回退 | MoonBit 单元、回归、失败契约和可执行文档测试 |
| 规范理解偏差 | 固定上游提交、逐文件哈希、许可证和完整 `mustache/spec` 报告 |
| 组合输入遗漏 | 四个固定 seed 的跨实现差分；JSON、逐 case JUnit、精确重放和失败自动最小化 |
| 测试“全绿但无辨别力” | 覆盖语义、安全路径和四种资源边界的可控故障矩阵，要求对应测试真实杀死 mutant，并输出逐项 JUnit |
| 编译目标行为分叉 | 同一 golden corpus 在 `wasm`、`wasm-gc`、`js`、`native` 逐字节比较 |
| CLI 契约错误 | 真实子进程验证退出码、文件 IO、严格失败、路径穿越和重复输出 |
| 未测试代码增长 | 核心库与 CLI 可测核心分别设覆盖率门禁，输出 Cobertura artifact 并检查指标新鲜度 |

所有当前精确数字、工具链版本和提交号只以自动生成的 [Metrics Snapshot](METRICS_SNAPSHOT.md) 为准，避免申报材料与代码漂移。

## 最佳文档辅助证据

- [可执行教程](../src/README.mbt.md) 覆盖基础渲染、Section/数组、Partial、严格诊断和多文件生成，随 `moon test` 执行。
- [Compatibility Lab](https://bellesz0611.github.io/moon-mustache/) 提供 Render、Diagnose、Compare、Conformance、Generate 五条评审路径。
- 文档检查拒绝断链、机器本地绝对路径和关键教程入口缺失。
- API、架构、兼容性、限制、稳定性、测试方法和发布边界分别成文。

## 三分钟可验证路径

1. Playground 渲染并触发严格缺失变量诊断。
2. Compare 即时展示 Moon Mustache 与 `mustache.js` 输出；Conformance 展示固定官方 corpus。
3. Generate 通过真实 MoonBit `TemplateBundle` 预览五文件 starter。
4. 打开指标快照，展示差分、Mutation、CLI、覆盖率和跨后端证据。
5. 本地运行 `python scripts/verify.py --profile full`，生成机器可读验收结果。
6. 推送后运行 `python scripts/check_submission_readiness.py`，要求两个镜像、默认入口内容和三条线上工作流都对应同一最终提交。

严格的屏幕动作与口播见 [三分钟演示脚本](DEMO_SCRIPT_3_MINUTES.md)。

## 可直接复制到申报表的短版说明

> Moon Mustache 以“分层且能证明有效”的测试体系申报最佳测试：固定来源的官方规范 fixture 验证语义，固定 seed 差分对比成熟实现并自动最小化失败样本，五类故障注入证明测试能识别真实回退，四后端 golden 比较防止目标分叉，CLI 黑盒测试覆盖退出码与安全路径，核心覆盖率和指标新鲜度由 CI 门禁。所有证据均可一键复现并输出 JSON、JUnit 或 Cobertura，不把不同统计单位拼成虚高总数。

## 证据边界

- imported fixture、生成差分 case 和 MoonBit test 不相加成一个“总测试数”。
- 本地无 C 编译器时 native build/test 明确跳过；GitHub Actions 必须执行 native lane。
- AI 协作不伪造 Issue、PR、人工审批或历史记录。
- 最新线上 CI、GitHub 与 GitLink 默认分支一致性必须在最终提交前再次核对。
