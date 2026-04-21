# 沉默失败排查指南

> 适用场景：无 ERROR 日志，但业务结果不符预期（AI 未回复、工单未创建、消息未同步等）。

## 核心思路

Intelli 是多服务链路（Webhook → Intelli → Tars → Bot API → 回调），某一环沉默返回或提前中断都不会触发 ERROR，但链路已断。**不要只看单服务日志，要看完整链路。**

## 排查步骤

### Step 1：获取 traceId

从请求日志或 Webhook 接收日志中找到 `traceId`（Aliyun ARMS 链路追踪 ID）。

### Step 2：下载 SLS 完整链路日志（含 DEBUG 级别）

```
1. 打开 Aliyun SLS 控制台
2. 选择对应的 Logstore
3. 搜索条件：traceId = "xxxxxxxx"
4. 时间范围：请求时间前后 5 分钟
5. 导出全量日志（含 DEBUG 级别，不要只看 ERROR/WARN）
```

### Step 3：按服务逐段排查

重点检查每个服务的出口日志：
- **Intelli**：是否收到 Webhook → 是否调用 Tars Bot API → 是否收到 callback
- **Tars**：是否收到请求 → `AiReplyNode` 是否执行 → botId/channelId 是否有值
- **Bot API**：是否返回 AI 内容

## 高频沉默失败场景

| 症状 | 根因 | 定位关键字 |
|------|------|-----------|
| AI 不回复，无报错 | `botId=null`，Tars AiReplyNode 跳过 | `context=false` / `botId is null` |
| Webhook 收到但无后续 | `hasPlatform()` 返回 false，路由到 V1 | `原始工单信息不存在` |
| 工单创建成功但无 AI | `tarsChannelId=null`，Tars 报 channelId required | `channelId is required` |
| 回复发送失败无报错 | 三方 API 返回 4xx 但被 catch 吞掉 | 查 ThirdPartyApiClient 响应体 |

## 预防

开发新平台时，在测试环境用真实 Webhook 触发一次完整链路，确认 SLS 日志中每个节点都有预期输出，再提测。
