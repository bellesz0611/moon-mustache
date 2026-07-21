# Community Post Draft

This is a ready-to-send short introduction for competition groups, community chats, or project showcases.

## Short version

我做了一个 MoonBit 的 Mustache 模板引擎项目 `moon-mustache`，现在已经支持：

- 核心 Mustache 渲染
- CLI / 文件输入输出 / bundle 校验
- 官方 `mustache/spec` fixture 对齐
- Vue playground
- 多个 consumer-style demo
- GitHub / GitLink / mooncakes.io / CI 全链路

仓库：

- GitHub: <https://github.com/bellesz0611/moon-mustache>
- GitLink: <https://www.gitlink.org.cn/miemie0619/moon-mustache-mbt>
- mooncakes: <https://mooncakes.io/docs/bellesz0611/moon-mustache%400.2.0>

欢迎试用、提 issue、给建议。

## Slightly longer version

`moon-mustache` 是一个面向 MoonBit 生态的 Mustache 模板引擎，主要服务脚手架生成、配置渲染、内容产出、多文件模板工程这类场景。现在项目已经不是壳仓库，包含：

- 自动化测试全量通过，精确数量见生成的 `docs/METRICS_SNAPSHOT.md`
- 194 / 194 官方核心及可选 `mustache/spec` fixture 通过
- 四个固定随机种子的差分用例与 `mustache.js` 输出一致，精确数量见生成指标快照
- 核心覆盖率与 CI 门槛以自动生成的 `docs/METRICS_SNAPSHOT.md` 为准
- 多条 GitHub Actions workflow
- GitHub 为主仓库；GitLink 镜像在正式提交前按同一 commit 校验
- mooncakes.io 已发布
- playground、static site、benchmark snapshot、多个 consumer demo

如果你愿意帮忙试一下，最欢迎两类反馈：

1. 文档哪里还不够清楚
2. 你会不会真的在某个 MoonBit 工具里用到这个库
