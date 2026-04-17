---
name: debug
description: Intelli + Tars integration debugging guide. Covers silent failures (no ERROR but wrong behavior), SLS log analysis, and direct aliyun CLI log queries. Use when a user reports unexpected behavior during integration testing — no AI reply, webhook not received, auth failure, etc.
version: 1.0.0
---

# intelli:debug — Integration Debugging Guide

## Purpose

测试阶段遇到集成问题时，引导或直接执行排查。覆盖两种模式：

- **引导模式**：用户提供日志或错误描述，分析并定位根因
- **直查模式**：本机已配置 `aliyun` CLI，直接查询 SLS 日志

## 触发时机

用户描述以下任一情况时主动调用：
- "没有 AI 回复" / "工单进了 Tars 但没有回复"
- "Webhook 没收到" / "授权失败"
- "报错了" + 粘贴了异常或日志片段
- "能帮我查一下日志吗"

---

## Step 0：判断排查模式

```
你现在有哪些信息？

A. 有错误日志 / 异常堆栈（直接粘贴过来）
B. 有 SLS 下载的日志文件（CSV / 原始文本）
C. 只知道现象，需要我直接查 SLS 日志
D. 其他
```

- 选 A → 进入 [错误日志分析](#错误日志分析)
- 选 B → 进入 [链路日志分析](#链路日志分析)
- 选 C → 进入 [SLS 直查模式](#sls-直查模式)
- 选 D → 收集现象描述，引导到最近的模式

---

## 错误日志分析

用户粘贴了异常堆栈或错误日志片段时，按以下顺序诊断：

### 常见错误模式

| 错误特征 | 根因 | 修复方向 |
|---------|------|---------|
| `unsupported platform` | Plugin JAR 不在 classpath | 检查 `shulex-intelli-api/pom.xml` 是否依赖了新模块 |
| `can not find channel auth type: live_agent` | `ChannelAuthTypeEnum` 缺少枚举值 | Tars 注册 `ChannelAuthTypeEnum` |
| `channelId, customer and messages are required` | `buildTicketConfig()` 未覆盖，`tarsChannelId=null` | `TicketPlatformPlugin.buildTicketConfig()` 必须覆盖，手动映射 `channelAuth.getId()` → `tarsChannelId` |
| `NullPointerException at BizScenarioFactory` | `createByChannelType()` 或 `createByTicket()` 缺少平台 case | Tars `BizScenarioFactory` 两个方法都要加 case |
| `NullPointerException at LocalDateTimeUtils.iso8601Str2Time` | `bornAt` 字段为 null | `TicketProcessingEngine.buildInboxMessages()` 已有修复，确认 SDK 版本 |
| `res?.data` 为 `undefined`（前端） | Controller 返回值未包 `ResponseResult<T>` | 检查所有 Controller 端点 |
| `No enum constant ExternKeySourceEnum.{PLATFORM}` | 调用了通用 `cancelChannel` 而非专用 auth 端点 | 实现专用 `DELETE /auth` 端点 |
| `getSetting` 返回 `authed=false` 但已授权 | `getSetting()` 未授权时返回 null 而非含 `authed=false` 的对象 | 未授权时返回 `new SettingResponse()`（`authed` 默认 false）|

### 操作

1. 匹配上表中的错误特征
2. 若未匹配，搜索 shulex-intelli 代码库定位异常抛出点
3. 输出根因 + 修复步骤

---

## 链路日志分析

用户提供了 SLS 下载的完整链路日志（CSV 或原始文本）。

### 分析步骤

**1. 提取关键业务节点**（过滤掉 SQL / Redis 噪声）

重点关注以下 class 的日志：
- `InboxController` — 入口请求，确认 channel / channelId / botId 是否正确传入
- `NodeComponent` — LiteFlow 节点执行顺序，找到异常短路点
- `AiReplyNode` — `context=false` = bot 未配置或被跳过
- `ExtensionExecutor` — 确认定位到正确的平台扩展点（`LiveAgentXxxExtPt` 而非 `DefaultXxxExtPt`）
- `ApiIntegrationGatewayImpl` — WARN 级别常含有 `botId=null` 等关键信息
- `AbstractInboxSaveDataExtPt` — `Ticket created: {id}` 确认工单已入库

**2. 识别沉默失败特征**

| 特征 | 含义 |
|------|------|
| `AiReplyNode finished in 2ms` | AI 回复被跳过（正常应 >100ms） |
| `context=false` | Bot 未配置，`botId=null` |
| `[Located Extension]: DefaultXxxExtPt` | 平台扩展点未注册，回落到默认实现 |
| `没有找到可用的automation` | 自动化规则未命中（非 bug，正常） |
| WARN `botId is null` | metadata 中 botId 未写入 |

**3. 追溯根因**

- 若 `botId=null`：`auth()` 保存时未调用 `gptBotFeign.getBots()` 写入
- 若定位到 `DefaultXxxExtPt` 而非平台扩展点：Tars 侧平台扩展点未注册
- 若节点执行链在某步骤提前结束：看该节点前后的 WARN/ERROR

---

## SLS 直查模式

本机已安装 `aliyun` CLI 并配置了 AccessKey 时，直接查询 SLS 日志。

### 前置检查

```bash
# 检查 aliyun CLI 是否可用
aliyun --version

# 检查是否已配置
aliyun configure list
```

若未配置，引导用户执行：
```bash
aliyun configure
# 依次填入：AccessKey ID / AccessKey Secret / 默认 region（cn-hangzhou 或 us-west-1）
```

### SLS 项目配置（Intelli staging 环境）

```
# Intelli 后端日志
region:   cn-hangzhou（或询问用户确认）
project:  shulex-intelli-staging（询问用户确认）
logstore: intelli-app

# Tars 后端日志
project:  aws-ticket-test（询问用户确认）
logstore: tars-app
```

> 首次使用时询问用户确认 project / logstore 名称，确认后记录到对话上下文。

### 查询模板

**1. 用 ticketId / externalId 找 traceId**

```bash
# 在 Intelli 日志中找 traceId
aliyun log get_log \
  --project=<project> \
  --logstore=intelli-app \
  --from=$(date -d '30 minutes ago' +%s) \
  --to=$(date +%s) \
  --query='ticketId:<TICKET_ID> | SELECT __time__, class, severity, rest LIMIT 20'
```

**2. 用 traceId 拉完整链路（Tars 侧）**

```bash
aliyun log get_log \
  --project=<project> \
  --logstore=tars-app \
  --from=<start_timestamp> \
  --to=<end_timestamp> \
  --query='traceId:<TRACE_ID> AND severity IN ("INFO","WARN","ERROR") | SELECT __time__, class, severity, rest ORDER BY __time__ LIMIT 500'
```

**3. 快速定位 AI 回复节点**

```bash
aliyun log get_log \
  --project=<project> \
  --logstore=tars-app \
  --from=<start> \
  --to=<end> \
  --query='traceId:<TRACE_ID> AND (class: AiReplyNode OR class: ApiIntegrationGateway OR severity: WARN) | SELECT __time__, class, severity, rest ORDER BY __time__'
```

**4. 批量查最近的错误**

```bash
aliyun log get_log \
  --project=<project> \
  --logstore=tars-app \
  --from=$(date -d '1 hour ago' +%s) \
  --to=$(date +%s) \
  --query='severity: ERROR AND channel: live_agent | SELECT __time__, class, rest LIMIT 50'
```

### 执行后分析

拿到日志输出后，进入 [链路日志分析](#链路日志分析) 流程。

---

## 常见场景快查

### 场景 1：工单进了 Tars 但没有 AI 回复

**排查顺序**：

1. 确认 `Ticket created: {id}` 存在（工单已入库）
2. 找 `AiReplyNode` — 是否 `context=false`？
3. 找 WARN `botId is null` — 是否 metadata 未写入 botId？
4. 找 `[Located Extension]` — 是否落到 `Default` 实现？
5. 找 `PostFilter rejected` — AI 有回复但被过滤？

### 场景 2：Webhook 没有触发

**排查顺序**：

1. 确认 Webhook URL 是否含 `/api_v2/intelli` 前缀（网关层）
2. Intelli 日志搜 `POST /v2/webhook/LIVEAGENT` — 是否有入口日志？
3. 若无入口日志 → 网络/DNS 问题，或 LiveAgent Rules 未配置
4. 若有入口但无后续 → `unsupported platform` 或 Plugin 未加载

### 场景 3：授权报错

1. 看 `auth()` 的入参是否完整（domain / apiKey 是否为空）
2. 看 `testCredentials()` 返回是否 false
3. 看 ChannelAuth 是否成功写入数据库（`channelAuthRepository.save()`）

### 场景 4：前端 `res?.data` 为 undefined

1. 检查对应 Controller 方法返回值是否包 `ResponseResult<T>`
2. 检查 `getSetting()` 未授权时是否返回含 `authed=false` 的对象（不能返回 null）

---

## Output Format

排查完成后输出：

```
排查结论：{一句话描述根因}

现象：{用户描述的问题}
根因：{技术根因，含具体类名/字段名}
证据：{日志关键行 或 代码位置}

修复步骤：
1. {步骤}
2. {步骤}

验证方式：{如何确认修复生效}
```
