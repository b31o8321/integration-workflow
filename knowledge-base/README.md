# Knowledge Base — 系统能力注册表

本目录记录 Intelli 和 shulex_gpt 的现有能力，供 `intelli:flow-analyze` 在链路验证时参照。

## 维护方式

运行 `/intelli:update-kb`（需要代码库通过 `/add-dir` 加入上下文）可自动分析并更新本目录文件。

每次更新后必须 bump `package.json` 版本号并 push，否则其他用户安装插件时不会拉取新版本。

## 版本 Bump 规则

| 变更类型 | 版本号 |
|---------|--------|
| 知识库更新、措辞修正 | x.x.N（patch） |
| 新增功能、流程调整 | x.N.0（minor） |
| 架构重构 | N.0.0（major） |

## 文件说明

| 文件 | 内容 |
|------|------|
| `intelli-capabilities.md` | Intelli SPI 接口实现状态 + 已接入平台列表 |
| `shulex-gpt-capabilities.md` | shulex_gpt AI 能力清单（语音/NLU/工具调用） |
