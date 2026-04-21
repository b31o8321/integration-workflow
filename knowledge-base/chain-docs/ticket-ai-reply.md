# 三方工单 AI 回复链路

> 适用场景：新平台接入工单 AI 回复功能时，理解完整处理流程。

## 整体流程

```
三方平台 Webhook → Controller
  → BaseTicket 实现类（ZendeskTicket / FreshdeskTicket 等）
  → reply() 判断同步/异步
    ├── 异步：提交 Redis ZSet 延迟队列 → DelayProcessTicketJob 定时拉取
    └── 同步：直接执行 replyTicket()
  → replyTicket()
  → Redis 会话锁（getConversationLockKey）
  → generalPreProcess() 前置过滤（已转人工/已回复/含附件 等）
  → GPT Bot API chat()
  → afterChat() 后置过滤
  → createMessage() 回复到三方平台
  → createTags() 打标签
  → 释放锁
```

## 关键文件

| 文件 | 路径 |
|------|------|
| 基类 | `shulex-intelli-integration/.../ticket/BaseTicket.java` |
| 延迟队列 Job | `shulex-intelli-api/.../job/DelayProcessTicketJob.java` |
| Zendesk 实现 | `shulex-intelli-integration/.../zendesk/ZendeskTicket.java` |
| Freshdesk 实现 | `shulex-intelli-integration/.../freshdesk/FreshdeskTicket.java` |

## V1 新平台接入步骤

1. 创建 `{Platform}Ticket extends BaseTicket`，实现所有抽象方法
2. 创建 `{Platform}Client extends ThirdPartyApiClient<ExternKey>`
3. 在 `DelayProcessTicketJob.replyTicket()` 添加平台分支
4. 创建 Webhook Controller

> V2 引擎接入见 `intelli-capabilities.md`，无需改 DelayProcessTicketJob。

## 关键设计

- **幂等**：Redis 会话锁，Key = `intelli:ticket:{platform}:lock:{tenantId}:{ticketId}`
- **异步延迟**：Redis ZSet，score = 执行时间戳；`metadata.setAsync(true)` 开启
- **转人工**：Bot API 返回 handoff action → 打标签 + 关闭 AI 处理

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 重复处理 | Webhook 重推/多实例 | 会话级 Redis 锁 |
| 异步丢失 | 未实现 getAsyncTicket | 必须实现并在 Job 添加分支 |
| AI 超时 | Bot API 慢 | 用异步模式 |
| 标签失败 | 三方限流 | 捕获异常，不影响主流程 |
