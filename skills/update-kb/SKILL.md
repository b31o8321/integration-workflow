---
name: update-kb
description: Analyze shulex_intelli and/or shulex_gpt codebases and update the plugin's knowledge-base capability registry. Requires /add-dir to load code into context first.
version: 1.0.0
---

# intelli:update-kb — 系统能力知识库更新

## Purpose

分析 shulex_intelli 和 shulex_gpt 代码库，更新 `knowledge-base/` 中的能力注册表。
更新后其他用户重装插件即可获得最新的系统能力信息，无需直接访问代码库。

## Pre-requisite Check

首先检查当前会话中可用的代码库：

```
检测上下文中的代码库...
```

使用 Glob 工具扫描已加载目录：
- 若找到 shulex_intelli → 分析 Intelli 能力
- 若找到 shulex_gpt → 分析 GPT 能力
- 若均未找到 → 输出以下提示并停止：

```
未检测到代码库。请先执行：

/add-dir <shulex_intelli 路径>
/add-dir <shulex_gpt 路径>

至少添加一个代码库后再运行 /intelli:update-kb。
```

## Analysis: shulex_intelli

若检测到 shulex_intelli，执行以下分析：

### 1. TicketEngine V2 SPI 接口实现状态

搜索 `TicketOperations` 接口定义，确认以下方法是否存在实现：
- `parseWebhook()`
- `extractCredentialKey()`
- `getMessages()`
- `getTags()`
- `getSubject()`
- `sendReply()`
- `applyTags()`

### 2. 已接入平台

搜索 `ExternKeySourceEnum`，列出所有已注册的平台枚举值。
搜索 `TicketPlatformPlugin` 的所有实现类，确认哪些平台已接入。

### 3. Livechat Engine 状态

搜索 Livechat 相关模块，确认：
- Webhook 接收模式实现状态
- WebSocket 接收模式实现状态
- Voice Session Manager 实现状态
- 出站消息发送实现状态

### 4. ISyncService 状态

搜索 `ISyncService` 实现类，列出已支持的同步类型。

### 5. Chain Docs 更新检查

读取 `knowledge-base/chain-docs/` 下所有文件，逐一核查以下内容是否仍与代码库匹配：

**ticket-ai-reply.md**
- `BaseTicket` 抽象方法列表是否完整（grep `abstract` in `BaseTicket.java`）
- `DelayProcessTicketJob.replyTicket()` 中的平台分支是否有新增
- 幂等锁 Key 格式是否变化

**voice.md**
- `VoiceTicketSystemResolver` 路由规则是否有新增平台/条件
- callType 映射表是否有新值
- 新增 Handler 实现类

**livechat-sync.md**
- `BaseLivechatClient` 抽象方法是否有变化
- 同步模式枚举是否新增
- `ExternChatRelationDO` 字段是否变化

**data-sync-job.md**
- `SyncExecutionEngine` 配置参数是否变化
- 分布式锁 Key 格式是否变化
- 新增 `ISyncService` 实现（对应新平台）

对每个文件：若代码与文档一致则跳过；若有差异则记录需更新的具体内容。

## Analysis: shulex_gpt

若检测到 shulex_gpt，执行以下分析：

### 1. 语音处理能力

搜索 ASR、TTS、语音流处理相关模块，确认：
- ASR 支持的引擎（Whisper / 云端等）
- TTS 支持语言
- 是否支持实时流式 ASR 及延迟水平

### 2. 意图识别 / NLU

搜索意图识别相关模块，列出已支持的意图类型。

### 3. Tool Call 支持

搜索 tool call / function call 相关实现，确认：
- 支持的格式（OpenAI / 其他）
- 最大并发 tool 数限制

### 4. 对话状态管理

搜索对话状态管理模块，确认多轮对话状态维护能力。

## Update knowledge-base Files

分析完成后，更新对应文件：

1. 读取 `knowledge-base/intelli-capabilities.md`（若分析了 shulex_intelli）
2. 读取 `knowledge-base/shulex-gpt-capabilities.md`（若分析了 shulex_gpt）
3. 对比分析结果与现有内容，更新变更项
4. 在文件头部更新"最后更新"日期
5. 新增能力标注 `NEW`，状态变更的标注 `UPDATED`

若 chain-docs 检查（Step 5）发现差异，同步更新对应的 `knowledge-base/chain-docs/*.md`：
- 只更新有实际差异的文件
- 在文件头部注释更新日期和变更摘要
- 不改动无变化的章节

## Post-Update Instructions

更新完成后输出：

```
knowledge-base 已更新：
{列出变更的文件和变更数量}

后续步骤：
1. 检查变更内容是否符合预期：
   git diff knowledge-base/

2. Bump package.json 版本号（patch 级别）：
   将 "version" 从 X.X.N 改为 X.X.N+1

3. Commit 并 push：
   git add knowledge-base/ package.json
   git commit -m "chore: update knowledge-base capabilities"
   git push

4. 团队成员重装插件获取最新版本：
   /plugin install intelli@intelli
   /reload-plugins
```
