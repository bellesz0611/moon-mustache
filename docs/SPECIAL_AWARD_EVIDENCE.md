# 专项鼓励奖证据索引

本页给评审提供一条不依赖口头说明、可在本地和 CI 重复执行的验收路径。Moon Mustache 的主申报方向是**最佳测试**，辅申报方向是**最佳文档**；AI 协作只陈述可审计事实，不把普通工具使用包装成成果。

## 1. 三分钟结论

Moon Mustache 是 MoonBit 原生 Mustache 引擎与安全多文件生成器。它不是只验证几个示例，而是用六类互补证据回答六种风险：

| 风险 | 证据 | 复现入口 |
| --- | --- | --- |
| 核心逻辑回退 | MoonBit 单元与回归测试 | `moon test --deny-warn --target wasm-gc` |
| 规范理解偏差或 fixture 来源漂移 | 固定上游提交、逐文件 SHA-256 与 `mustache/spec` fixture | `python scripts/verify_official_spec_fixtures.py && moon run official_spec_report` |
| 组合输入遗漏 | 四个固定 seed 的 `mustache.js` 差分测试 | `cd playground && npm run differential` |
| CLI 只“能跑”但契约错误 | 真实子进程、退出码和文件产物断言 | `python scripts/test_cli_integration.py` |
| 未测试代码持续增长 | 核心覆盖率 CI 门禁和 Cobertura artifact | GitHub Actions `ci.yml` |
| 测试虽通过但无法识别关键回退 | 五类可控故障注入，要求对应回归测试真实失败 | `python scripts/run_fault_injection.py` |

精确的测试数、fixture 通过数、覆盖率分子分母、工具链版本和对应提交，只引用自动生成的 [METRICS_SNAPSHOT.md](METRICS_SNAPSHOT.md)。这样可以避免 README、进度表和申报材料出现不同数字。

## 2. 最短验收路径

一条命令生成逐步日志与机器可读摘要：

```bash
python scripts/verify.py
```

`python scripts/verify.py --profile full` 还会运行其余后端和 Playground。若本机没有 C 编译器，native build/test 会明确记为 `skipped`；GitHub Actions 的 Linux native lane 仍必须实际通过。

等价的分步命令：

```bash
moon fmt --check
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
python scripts/verify_official_spec_fixtures.py
moon run official_spec_report
python scripts/test_cli_integration.py
python scripts/run_coverage.py --minimum 88
python scripts/run_fault_injection.py
python scripts/check_docs.py
python scripts/check_metrics_freshness.py
```

完整跨实现验证：

```bash
cd playground
npm ci
npm run differential
npm run build
```

CI 会在 `wasm`、`wasm-gc`、`js`、`native` 四个目标执行 check/build/test；`js` lane 额外运行 CLI 黑盒集成套件并上传 JSON 结果，`wasm-gc` lane 离线核验固定上游 fixture 并上传完整性 JSON、覆盖率摘要和 Cobertura XML。

## 3. 最佳测试：可检查的主张

### 3.1 测试分层而不是累加数字

- 单元测试定位 scanner、parser、lookup、renderer、diagnostics、bundle 等模块回退。
- 官方 fixture 验证对 Mustache 既有语义的理解，不把自定义用例当作规范本身；来源 commit、逐文件 SHA-256、case 数与生成文件哈希由 manifest 固定并在 CI 离线验证。
- 差分测试以四个固定 seed 生成组合输入，对比另一个成熟实现，并为失败样本生成精确重放命令。
- CLI 集成测试从 Python 启动真实 MoonBit JS CLI，断言 stdout、退出码和磁盘产物。
- 四后端矩阵负责发现目标相关问题，Windows job 负责浏览器桥和路径差异。
- 可控故障注入在临时副本中破坏转义、truthiness、路径保护、Partial 深度和父上下文查找，只有对应测试真实失败才算 mutant 被杀死。

这些数量不能相加成一个“总测试数”：单元 case、官方 fixture 和差分输入代表不同统计单位。

### 3.2 本轮新增的缺陷证明

黑盒测试落地前，`--strict --strict-missing` 能阻止输出，却仍返回退出码 `0`；文件不存在的严格渲染同样返回 `0`。这会让 CI 误判成功。本轮已把失败契约修正为非零退出码，并用以下用例防止回归：

1. inline render 成功且输出精确匹配；
2. file-backed render 成功且 partial 生效；
3. strict missing 返回非零并解释阻断原因；
4. lint parse error 返回非零且保留稳定错误码；
5. bundle 生成五个预期产物，profile 和 validation plan 内容正确。

实现见 [`scripts/test_cli_integration.py`](../scripts/test_cli_integration.py)，CI 配置见 [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)。

### 3.3 测试有效性证明

[`scripts/run_fault_injection.py`](../scripts/run_fault_injection.py) 每次只在临时项目副本中注入一个故障，并运行一个直接对应风险的回归测试。五个 mutant 必须全部被测试失败杀死；编译错误、目标锚点漂移、超时和存活 mutant 都会让命令失败。具体故障和边界见 [Controlled Fault Injection](FAULT_INJECTION.md)。

### 3.4 证据边界

- “核心覆盖率”只统计 `src/`，不冒充整个仓库覆盖率。
- CLI 与 bridge 主要由黑盒集成和 smoke job 覆盖，与核心单元覆盖率分开陈述。
- imported fixture 生成代码与手写实现行数分开披露。
- 固定 seed 组证明可重复性，不等于穷举全部模板空间。

## 4. 最佳文档：文档本身可验证

- 首页只保留一个主任务、快速运行、测试证据、常用接口和导航，不再堆叠比赛口号。
- [`src/README.mbt.md`](../src/README.mbt.md) 中的入门示例使用 `mbt check`，随包一起编译检查。
- `python scripts/check_docs.py` 检查 Markdown 本地链接，拒绝开发者机器上的绝对路径。
- 指标集中在生成文件，其他文档引用它而不复制易过期数字。
- API、兼容性、架构、稳定性和已知限制各有明确入口。

## 5. AI 协作证据边界

仓库现在提供 [`AGENTS.md`](../AGENTS.md)、[AI 协作实践](AI_COLLABORATION.md) 和 PR 人工复核清单，并记录了 CLI 退出码与覆盖率统计两个真实案例。若申报“最佳 AI 协作实践”，仍只提交真实可追溯的计划、补丁、失败测试、人工复核和 CI 记录，不伪造历史对话、PR 或审批记录。当前最强证据依然是测试与文档工程。

## 6. 评审建议顺序

1. 在在线 Playground 完成一次模板渲染；
2. 运行 CLI 黑盒集成套件，观察严格失败退出码；
3. 查看官方 fixture 报告与差分测试输出；
4. 打开 CI artifact 核对 coverage 与 JSON 结果；
5. 修改 `src/README.mbt.md` 示例后运行 `moon test`，验证可执行文档会真实失败。
