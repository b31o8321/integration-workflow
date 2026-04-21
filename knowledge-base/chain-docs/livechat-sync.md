# 三方 Livechat 数据同步链路

> 适用场景：接入三方 Livechat 平台，理解双向消息同步机制。

## 整体流程

```
【Lead → 三方平台方向】
Shulex Livechat → Kafka: livechat-event
  → ThirdPartyLivechatEventConsumer（批量消费）
  → Redis 幂等检查（Key: livechat:event:{tenantId}:{messageId}，2天过期）
  → 查询 ExternChatRelation（Shulex chatId ↔ 三方 conversationId 映射）
  → BaseLivechatClient.syncLeadMessage()
    ├── 首次：createLeadUser() + createConversation() → 保存 ExternChatRelation
    └── 已有：直接取 conversationId
  → createLeadMessage() 同步消息到三方平台
  → [转人工] onHandOff()

【三方平台 → Shulex 方向】
三方平台 Webhook → Controller
  → BaseLivechatClient.createAgentMessage()
  → 查 ExternChatRelation 获取 chatId
  → syncAgentMessage() 同步到 Shulex Livechat
```

## 关键文件

| 文件 | 路径 |
|------|------|
| 消费者 | `shulex-intelli-api/.../mq/consumer/ThirdPartyLivechatEventConsumer.java` |
| 基类 | `shulex-intelli-integration/.../livechat/BaseLivechatClient.java` |
| 关系映射实体 | `shulex-intelli-common/.../entity/tars/ExternChatRelationDO.java` |

## 同步模式

| 模式 | 含义 |
|------|------|
| `SYNC_ON_START` | 会话开始立即同步 |
| `SYNC_ON_HANDOFF` | 仅转人工时同步（含历史消息） |

## 新增三方平台步骤

1. 创建 `{Platform}LivechatClient extends BaseLivechatClient`，实现所有抽象方法
2. 创建 `{Platform}ApiClient extends ThirdPartyApiClient<ExternKey>`
3. 配置 `LivechatMetadata`（apiBaseUrl / accessToken / botId / xToken / syncMode）
4. 在 `ExternKeySourceEnum` 添加枚举值

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 消息重复 | Kafka 重消费 | Redis 幂等 Key，2天过期 |
| 会话映射丢失 | ExternChatRelation 未保存 | 创建会话后立即保存 |
| 历史消息丢失 | SYNC_ON_HANDOFF 模式 | 调用 TranscriptApi 获取全部历史 |
| 并发重复创建会话 | 多消息同时到达 | 分布式锁，Key=chatId |
| 消息乱序 | Kafka 多分区 | 以 chatId 为 Kafka 消息 Key |
