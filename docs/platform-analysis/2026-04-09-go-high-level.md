# Go High Level 接入可行性评估

> 分析日期: 2026-04-09
> 分析人: Claude (intelli:analyze)
> 数据来源: https://marketplace.gohighlevel.com/docs/oauth/GettingStarted + https://highlevel.stoplight.io/docs/integrations/
> 业务场景: 美业门店外呼潜在客户，AI 语音/SMS 引导预约

---

## 一、结论（PM / 交付用）

| 功能 | 结论 | 说明 |
|------|------|------|
| 工单AI回复 | ✅ 可行 | Conversation 映射为 ticket，Webhook + 消息读写 + Tag 全部原生支持 |
| Livechat对接（SMS 外呼） | ⚠️ 部分可行（需适配） | 原生支持发起外呼/SMS；入站 webhook-only，需适配层；无 WebSocket |
| Livechat对接（语音外呼） | ⚠️ 部分可行（需新链路） | GHL 可发起外呼电话，但 AI 语音处理同 Zoom CC，需 Voice Engine 新链路 |
| 数据同步（联系人/Lead） | ✅ 可行 | 联系人增量同步完整支持，ISyncService 直接套用 |

### 建议

GHL 是外呼场景的核心平台，建议分两阶段实施：**第一阶段**优先实现 SMS 外呼（简单改造，2–4 天），通过 SMS 触达潜在客户引导自助预约；**第二阶段**在 AI Voice Engine 就绪后叠加语音外呼能力。联系人数据同步可与 Zenoti 集成同步开发，工时短且无阻塞。

---

## 二、技术差距分析（研发用）

### 工单AI回复

**可行性：** ✅ 可行

**差距列表：**

- [Minor, <1天] **getSubject() 无原生字段** — GHL Conversation 无 subject 字段；构造方式：`{channel类型} with {联系人姓名}`（如 "SMS with 张三"）。在 `getSubject()` 实现中拼接，不影响其他接口。

**预估工作量：** 小（3–5 天，含 adapter 实现、webhook 注册、联调）

---

### Livechat对接（SMS / 外呼）

**可行性：** ⚠️ 部分可行（SMS 外呼：简单改造；语音外呼：需新链路）

**差距列表：**

- [Medium, 2–3天] **无 WebSocket** — 入站消息通过 `InboundMessage` webhook 推送，需实现 webhook → Livechat Engine 适配层（公网 callback endpoint + 消息路由）。
- [Minor, <1天] **无显式 transfer 事件** — 无 agent 转接专用 webhook；用会话 close + 打 tag（如 `transferred-to-human`）模拟。
- [新链路] **AI 语音外呼** — GHL `type="Call"` 可发起外呼，但 AI 语音对话处理需 Voice Engine（同 Zoom CC），为新链路设计。若仅 SMS 触达则不涉及。

**预估工作量（SMS 外呼路径）：** 中（1 周，含 webhook adapter + 外呼触发 + 状态回调处理）

---

### 数据同步（联系人/Lead）

**可行性：** ✅ 可行

**差距列表：**

- [Minor, <1天] **Rate limit 无稳定 header** — `x-ratelimit-*` 返回不稳定；以 429 + 指数退避为主要限速信号，header 仅作辅助参考。

**预估工作量：** 小（2–3 天，含 ISyncService 实现 + 增量同步逻辑 + 退避策略）

---

## 三、接入 Checklist（研发用）

### 工单AI回复接入 Checklist

- [ ] `ExternKeySourceEnum` 中注册 `GO_HIGH_LEVEL` 枚举值
- [ ] 创建 Maven 子模块 `intelli-ticket-gohighlevel`
- [ ] 实现 `TicketPlatformPlugin`
  - [ ] `platformId()` 返回 `GO_HIGH_LEVEL`
  - [ ] `extractCredentialKey()` 从 webhook URL token 或 locationId 提取
  - [ ] `parseWebhook()` 解析 `InboundMessage` / `ConversationUnread` payload + HMAC-SHA256 签名验证（`x-wc-webhook-signature`）
  - [ ] `createOperations()` 创建 ExternKey
  - [ ] `parsePlatformConfig()` 解析 GHL locationId + OAuth token 配置
- [ ] 实现 `TicketOperations`
  - [ ] `getMessages()` — `GET /conversations/{id}/messages`
  - [ ] `getTags()` — `GET /contacts/{id}` → `tags[]`
  - [ ] `getSubject()` — 构造：`{channel} with {contactName}`
  - [ ] `sendReply()` — `POST /conversations/messages`（type: SMS/Email/WhatsApp）
  - [ ] `applyTags()` — `POST /contacts/{id}/tags`（支持批量，单次调用）
  - [ ] `lockKey()` 包含 tenantId + conversationId
- [ ] 创建 `AutoConfiguration` 并注册
- [ ] 配置 `intelli.ticket.v2.enabled=true`
- [ ] 配置 webhook URL 并在 GHL Marketplace App 注册

### Livechat接入 Checklist（SMS 外呼）

- [ ] 实现 Webhook 接收适配层
  - [ ] 公网 endpoint 注册：`/livechat/ghl/webhook`
  - [ ] `InboundMessage` 事件解析 → Livechat Engine inbound 消息格式
  - [ ] 消息幂等 key：`messageId`（scoped by `conversationId`）
- [ ] 实现 outbound 消息发送
  - [ ] SMS：`POST /conversations/messages`（`type: "SMS"`）
  - [ ] 外呼发起：`POST /conversations/messages`（`type: "Call"`）
- [ ] 实现 session 生命周期处理
  - [ ] `ConversationUnread` → session open
  - [ ] Conversation close event → session close
  - [ ] No-answer / busy 回调 → 重试队列或 SMS 降级
- [ ] 接入 Kafka 消息管道

### 数据同步接入 Checklist（联系人/Lead 同步）

- [ ] 实现 `ISyncService` 联系人增量同步
  - [ ] 增量拉取参数：`startAfterDate` + `endDate`
  - [ ] 分页实现：`startAfterId` cursor，`limit=100`
  - [ ] 字段映射：GHL Contact → Intelli Customer 模型
- [ ] Rate limit 处理：429 触发指数退避；有 `x-ratelimit-remaining` 时做预防性限速
- [ ] 定时任务：建议每 15 分钟增量同步一次
