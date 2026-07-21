# 三分钟专项奖演示脚本

目标：在 `3:00` 内证明“产品可用、测试可信、证据可复现”。演示前打开在线 Playground、[Metrics Snapshot](METRICS_SNAPSHOT.md) 和终端；浏览器缩放保持 100%。

| 时间 | 屏幕动作 | 口播重点 |
| --- | --- | --- |
| `0:00–0:20` | Playground 首页，停留在中文标题和五个页签 | “Moon Mustache 是 MoonBit 原生 Mustache 引擎和安全多文件生成器。今天不展示堆功能，而展示它如何证明自己可靠。” |
| `0:20–0:45` | Render 选择 Welcome，再切 Missing Variable | “浏览器直接运行编译后的 MoonBit 引擎。模板、JSON、Partial 和输出在同一流程里；严格模式不会隐藏缺失数据。” |
| `0:45–1:05` | 切到 Diagnose，指出诊断数和 missing variable | “输出与诊断分离，库调用者可以预览结果，同时让 CI 或编辑器阻断不完整输入。” |
| `1:05–1:25` | 切 Compare，再切 Conformance | “Compare 对当前输入即时调用 `mustache.js`；Conformance 的 suite、case 数和哈希直接读取锁定的上游 manifest，不是页面手填。” |
| `1:25–1:50` | 切 Generate，点击 Generate project，滚动五个 artifact | “这不是字符串玩具。真实 `TemplateBundle` 一次生成 `moon.mod`、README、源码、包配置和 CI，浏览器只预览、不写磁盘。” |
| `1:50–2:10` | 打开 Metrics Snapshot 的 Verification 段 | “精确测试数和覆盖率只维护在生成快照。官方 fixture、单测、差分输入互不混算，避免虚高指标。” |
| `2:10–2:35` | 打开 `DIFFERENTIAL_TESTING.md` 和 `FAULT_INJECTION.md` | “固定 seed 差分提供逐 case JUnit、精确重放，并自动缩小失败模板、上下文和 Partial。五类受控故障必须让对应测试失败，证明测试有辨别力。” |
| `2:35–2:50` | 终端展示 `python scripts/verify.py --profile full` 的最终摘要 | “一条命令串起文档、fixture 完整性、后端、CLI、覆盖率、Mutation、差分和 Playground build，并输出机器可读证据。” |
| `2:50–3:00` | 回到一页申报稿结论 | “因此主申报最佳测试，辅申报最佳文档：重点不是测试多，而是每个风险都有独立、可重放、能发现故障的证据。” |

## 演示前检查

```bash
python scripts/check_docs.py
python scripts/check_metrics_freshness.py
python scripts/verify.py --profile full
python scripts/check_submission_readiness.py
```

- 确认在线 Playground 对应最终提交，而不是本地领先版本。
- 确认 GitHub、GitLink 默认入口展示同一提交。
- 提前打开页面，避免现场等待依赖安装或 Pages 冷启动。
- 终端只展示最终摘要；详细日志保留在 `_artifacts/verification/` 供追问时打开。

## 离线备用路径

若网络不可用，运行：

```bash
cd playground
npm run build
npm run preview -- --host 127.0.0.1
```

同时保留上一轮完整验收的 `verification.json`、差分 JSON/JUnit、覆盖率 Cobertura 和故障注入 JSON。离线材料只作为同一提交的备份，不使用无法核对来源的截图代替证据。
