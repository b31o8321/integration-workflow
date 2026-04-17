---
name: debug
description: Intelli + Tars integration debugging guide. Guides users through finding armsTrace, downloading full chain logs from SLS/ARMS, and analyzing them. Use when a user reports unexpected behavior during integration testing — no AI reply, webhook not received, auth failure, etc.
version: 1.1.0
---

# intelli:debug — Integration Debugging Guide

## Purpose

集成测试遇到问题时，**引导排查流程**，帮助用户获取完整链路日志并定位根因。

核心思路：**通过 armsTrace 获取全链路日志 → 分析 → 定位根因**

## 触发时机

用户描述以下任一情况时主动调用：
- "没有 AI 回复" / "工单进了 Tars 但没有回复"
- "Webhook 没收到" / "授权报错" / "前端报错"
- 粘贴了异常堆栈或错误日志片段
- "能帮我查日志吗" / "怎么排查"

---

## Step 1：获取 armsTrace

armsTrace 是分布式链路追踪 ID，能把 Intelli + Tars 跨服务调用串联成一条完整链路。

### 1a. 从已有日志中找 armsTrace

如果用户已经粘贴了部分日志（错误堆栈或日志片段），直接从中提取：

```
# armsTrace 格式示例（32位十六进制）
armsTrace: 5b242d7d8277fb3ba42ecf91136ed3e2

# 常见位置：
# - 日志行的 armsTrace 字段
# - 错误堆栈上方的 traceId 字段
# - SLS 日志中的 armsTrace 列
```

### 1b. 无日志时，引导用户找 armsTrace

询问用户：

```
你能提供以下任意一项吗？

1. LiveAgent 工单 ID（ticketId，如 "yrhi74ul"）
   → 用它在 SLS 搜索对应的 armsTrace

2. 操作发生的大致时间（精确到分钟）
   → 缩小 SLS 搜索范围

3. 直接在阿里云 ARMS 控制台搜索
   → ARMS 控制台 → 应用监控 → 调用链查询 → 按时间段搜索
```

---

## Step 2：用 armsTrace 下载完整链路日志

获取到 armsTrace 后，引导用户在 **SLS（阿里云日志服务）** 下载完整链路：

### SLS 查询步骤

```
1. 打开 SLS 控制台 → 进入 Intelli / Tars 对应的 Logstore
2. 时间范围：设置为问题发生前后各 5 分钟
3. 查询语句：armsTrace: <armsTrace值>
4. 查询结果 → 点击"下载" → 选择"下载全部日志（含 DEBUG）"
5. 格式选 CSV，下载后发给我
```

> **为什么要包含 DEBUG**：沉默失败（无 ERROR 但功能不生效）往往只出现在 DEBUG/INFO 级别。仅下载 ERROR 日志会遗漏关键信息。

### 如果用户没有 SLS 权限

引导通过阿里云 ARMS 直接查看：

```
ARMS 控制台 → 应用监控 → 选择 intelli 应用 → 调用链查询
→ 输入 TraceId（即 armsTrace）→ 查看完整调用链详情
→ 截图或复制关键节点信息发给我
```

---

## Step 3：分析链路日志

用户把日志文件发过来后，按以下框架分析：

### 3a. 定位关键节点（按时间顺序）

重点关注以下 class 的日志，过滤掉 SQL / Redis 噪声：

| 关注点 | Class 关键词 | 含义 |
|-------|------------|------|
| 入口请求 | `InboxController` | 确认 channel / channelId / botId 是否传入 |
| 流程节点 | `NodeComponent` | LiteFlow 执行链，找短路点 |
| AI 回复决策 | `AiReplyNode` | `context=false` = bot 未配置 |
| 扩展点定位 | `ExtensionExecutor` | 是否落到 `DefaultXxxExtPt`（表示平台扩展点未注册） |
| 关键警告 | `ApiIntegrationGatewayImpl` | WARN 常含 `botId=null` 等根因 |
| 工单入库 | `AbstractInboxSaveDataExtPt` | `Ticket created: {id}` 确认工单已建 |

### 3b. 识别沉默失败特征

| 特征 | 含义 | 典型根因 |
|------|------|---------|
| `AiReplyNode finished in 2ms, context=false` | AI 回复被跳过 | `botId=null`，metadata 未写入 |
| `[Located Extension]: DefaultXxxExtPt` | 平台扩展点未注册 | Tars 侧 BizConstants / ExtPt 未实现 |
| `hasPlatform` 返回 false | platformId 与 ExternKeySourceEnum.name() 不匹配 | platformId 命名不规范（如 LIVEAGENT vs LIVE_AGENT）|
| `原始工单信息不存在` | Tars callback 路由到 V1 路径 | 同上，platformId 不匹配导致 hasPlatform=false |
| `PostFilter rejected: action=SKIP` | AI 有回复但被过滤 | 查 `reason=` 字段 |

### 3c. 输出排查结论

```
排查结论：{一句话根因}

现象：{用户描述}
根因：{技术根因，含类名/字段名}
证据：{关键日志行}

修复步骤：
1. {步骤}
2. {步骤}

验证：{重新触发 Webhook，确认 AiReplyNode 不再 context=false}
```

---

## 常见场景快查

不用等完整日志，常见错误信息可直接对照：

| 错误信息 | 根因 | 修复 |
|---------|------|------|
| `原始工单信息不存在` | `platformId` 与 `ExternKeySourceEnum.name()` 不匹配 | 使 `PLATFORM_ID = ExternKeySourceEnum.LIVE_AGENT.name()` |
| `can not find channel auth type: live_agent` | Tars `ChannelAuthTypeEnum` 缺枚举值 | Tars 注册 `LIVEAGENT` 枚举 |
| `channelId, customer and messages are required` | `buildTicketConfig()` 未覆盖，tarsChannelId=null | 覆盖 `buildTicketConfig()`，手动映射 `channelAuth.getId()` |
| `NullPointerException at BizScenarioFactory` | `createByTicket()` 或 `createByChannelType()` 缺 case | Tars 两个方法都要加 case |
| `unsupported platform` | Plugin JAR 未在 classpath | 检查 `shulex-intelli-api/pom.xml` 依赖 |
| 前端 `res?.data` 为 undefined | Controller 未包 `ResponseResult<T>` | 检查返回值包装 |

---

## 附：aliyun CLI 直查（可选）

本机配置了 `aliyun` CLI 时，可以直接代为查询（无需用户手动下载）：

```bash
# 检查是否可用
aliyun --version && aliyun configure list
```

如可用，直接执行查询：

```bash
# 用 ticketId 找 armsTrace
aliyun log get_log \
  --project=<project> --logstore=<logstore> \
  --from=$(date -v-30M +%s) --to=$(date +%s) \
  --query='ticketId:<TICKET_ID> | SELECT armsTrace LIMIT 5'

# 用 armsTrace 拉全链路 INFO+WARN+ERROR
aliyun log get_log \
  --project=<project> --logstore=<logstore> \
  --from=<start> --to=<end> \
  --query='armsTrace:<TRACE_ID> AND severity IN ("INFO","WARN","ERROR") | SELECT __time__, class, severity, rest ORDER BY __time__ LIMIT 500'
```

> project / logstore 名称首次使用时询问用户确认。
