# Intelli 系统能力

> 最后更新: 2026-04-09（占位版本，请运行 /intelli:update-kb 更新真实数据）

## TicketEngine V2 SPI

| 接口方法 | 状态 | 备注 |
|---------|------|------|
| `parseWebhook()` | ✅ | |
| `extractCredentialKey()` | ✅ | |
| `getMessages()` | ✅ | |
| `getTags()` | ✅ | |
| `getSubject()` | ✅ | |
| `sendReply()` | ✅ | |
| `applyTags()` | ✅ | |

## 已接入平台（TicketEngine）

| 平台 | 状态 | 备注 |
|------|------|------|
| Zendesk | ✅ | |
| Freshdesk | ✅ | |
| （更多平台请运行 update-kb 更新） | | |

## Livechat Engine

| 能力 | 状态 | 备注 |
|------|------|------|
| Webhook 接收模式 | ✅ | |
| WebSocket 接收模式 | ❌ | 未实现 |
| Voice Session Manager | ❌ | 未实现 |
| 出站消息发送 | ✅ | |
| Session 生命周期管理 | ✅ | |

## ISyncService

| 同步类型 | 状态 | 备注 |
|---------|------|------|
| 订单同步 | ✅ | |
| 商品同步 | ✅ | |
| 物流同步 | ⚠️ | 部分支持 |
