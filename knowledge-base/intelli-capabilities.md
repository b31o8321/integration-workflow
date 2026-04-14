# Intelli 系统能力

> 最后更新: 2026-04-14（by 复盘修正：ChannelAuth 为新平台标准）

## TicketEngine V2 SPI

### 凭证模式说明

> ⚠️ **新平台一律使用 ChannelAuth 模式，不使用 ExternKey 模式。**

| 模式 | 表 | 枚举 | 适用场景 |
|------|----|------|---------|
| **ChannelAuth（新）** | `channel_auth` | `ChannelTypeEnum` | **所有新接入平台**，覆盖 `resolveCredential()` + `resolveCredentialByKey()`，参考 `LineTicketPlugin` |
| ExternKey（遗留）| `extern_key` | `ExternKeySourceEnum` | 存量平台（Gorgias、Zendesk 等），新平台不再使用 |

新平台接入 Checklist（凭证相关）：
- [ ] `ChannelTypeEnum` 新增枚举值
- [ ] 实现 `XxxChannelAuthCredential implements TicketCredential`（appKey=domain, channelSecret=密钥）
- [ ] `XxxTicketPlugin` 覆盖 `resolveCredential()` 和 `resolveCredentialByKey()`
- [ ] `XxxTicketAutoConfiguration` 注入 `IChannelAuthRepository` + `ApiKeyService`
- [ ] Controller 使用 `IChannelAuthRepository` 存储 ChannelAuthDO

### TicketPlatformPlugin 接口

| 接口方法 | 状态 | 备注 |
|---------|------|------|
| `parseWebhook()` | ✅ | 签名验证在方法内部实现 |
| `extractCredentialKey()` | ✅ | 从 URL path token 提取 |
| `createOperations()` | ✅ | 支持带 TicketEvent 的重载版本 |
| `resolveCredential()` | ✅ | **新平台必须覆盖**。新平台一律使用 ChannelAuth 模式（`IChannelAuthRepository`），不走默认 ExternKey CredentialResolver。参考 `LineTicketPlugin.resolveCredential()` |
| `resolveCredentialByKey()` | ✅ | **新平台必须覆盖**。同上，用 rawToken → ApiKeyService → tenantId → ChannelAuth。参考 `LineTicketPlugin.resolveCredentialByKey()` |
| `parsePlatformConfig()` | ✅ | 解析 ExternKey.metadata JSON |

### TicketOperations 接口

| 接口方法 | 状态 | 备注 |
|---------|------|------|
| `getMessages()` | ✅ | 返回标准化 TicketMessage 列表 |
| `getTags()` | ✅ | 返回 List<String> |
| `getSubject()` | ✅ | 返回工单 subject 字符串 |
| `sendReply()` | ✅ | 发送 AI 回复 |
| `sendHumanReply()` | ✅ | 默认回退到 sendReply，富媒体平台可覆盖 |
| `applyTags()` | ✅ | 批量打标签 |
| `lockKey()` | ✅ | 幂等锁 key，可平台自定义 |

### 已实现 TicketPlatformPlugin 的平台（新 SPI）

| 平台 | 凭证模式 | 参考实现 | 备注 |
|------|---------|---------|------|
| LINE | ChannelAuth ✅ | `LineTicketPlugin` | 标准参考实现，新平台照此模式 |
| LiveAgent | ChannelAuth ✅ | `LiveAgentTicketPlugin` | 无 HMAC，URL path token 替代签名 |
| Gorgias | ExternKey（遗留）| `GorgiasTicketPlugin` | 旧模式，不作为新平台参考 |
| 其他平台 | ExternKey（遗留）| — | 通过旧版适配层接入，未迁移到新 SPI |

## 已接入平台

### ChannelAuth 模式（新）

| 平台 | 类型 | 状态 |
|------|------|------|
| LINE | Ticket | ✅ |
| LiveAgent | Ticket | ✅ |

### ExternKey 模式（遗留）

> 存量平台维护用，新平台不再新增。

| 平台 | 类型 | 状态 |
|------|------|------|
| Zendesk | Ticket + Livechat | ✅ |
| Freshdesk | Ticket | ✅ |
| Freshchat | Livechat | ✅ |
| Intercom | Ticket | ✅ |
| Gorgias | Ticket + Livechat | ✅ |
| ZOHO | Ticket | ✅ |
| ZOHO_LIVECHAT | Livechat | ✅ |
| Sunshine（Zendesk Livechat） | Livechat | ✅ |
| SOBOT | Livechat | ✅ |
| NEXTOP / NEXTOP_LIVECHAT | Ticket + Livechat | ✅ |
| UDESK / UDESK_V2 | Ticket | ✅ |
| EDESK | Ticket | ✅ |
| SERVICE_NOW | Ticket | ✅ |
| LINE | Ticket | ✅ |
| TIKTOK_SHOP | Ticket | ✅ |
| GMAIL | Ticket | ✅ |
| SALESFORCE | Ticket | ✅ |
| Shopify | 数据同步 | ✅ |
| Shopline | 数据同步 | ✅ |
| Amazon | 数据同步 | ✅ |
| eBay | 数据同步 | ✅ |
| Walmart | 数据同步 | ✅ |
| Miva | 数据同步 | ✅ |
| LINGXING | 数据同步 | ✅ |
| G_ERP | 数据同步 | ✅ |
| BANMA | 数据同步 | ✅ |
| ECCANG | 数据同步 | ✅ |

## Livechat Engine

| 能力 | 状态 | 备注 |
|------|------|------|
| Webhook 接收模式 | ✅ | 主要接入方式，所有 Livechat 平台均支持 |
| WebSocket 推送（下行） | ✅ | Intelli → 前端 Agent 界面，通过 `WebSocketMsgType` 推送 |
| WebSocket 接收模式（上行三方） | ❌ | 未实现，三方 Livechat 消息均通过 Webhook 接收 |
| Voice Session Manager | ❌ | 未实现独立 Voice Session，VoiceTicketSyncEngine 仅处理语音转工单场景 |
| 出站消息发送 | ✅ | 每个 `BaseLivechatClient` 实现均有 `createAgentMessage()` |
| Session 生命周期管理 | ✅ | `createConversation()` / session close 均实现 |
| 已接入 Livechat 平台 | ✅ | Zendesk Sunshine、ZendeskBot、Nextop、Zoho、Sobot、Gorgias、Freshchat |

## ISyncService（后台数据同步）

| 同步类型 | 状态 | 已接入平台 |
|---------|------|---------|
| 订单同步（AbstractOrderSyncService） | ✅ | Shopify、Shopline、Amazon、eBay、Walmart、Miva |
| 商品同步（AbstractProductSyncService） | ✅ | Shopline、Miva |
| 物流同步（AmazonFulfillmentSyncService） | ✅ | Amazon |
| 全量报告同步（AmazonOrderReportSyncService） | ✅ | Amazon |
| eBay 专属同步（EbaySyncService） | ✅ | eBay |
| Walmart 专属同步（WalmartSyncService） | ✅ | Walmart |

## IQueryOrderService（AI Tool 订单查询）

供 shulex_gpt AI 作为 Tool Call 实时调用，在对话中查询订单信息。

| 接口方法 | 状态 | 备注 |
|---------|------|------|
| `queryOrder()` v1 | ✅ | 按订单 ID 查询单条 |
| `queryOrderV2()` v2 | ✅ | 按订单号查询，返回标准 OrderDTO |
| `queryOrders()` | ✅ | 批量查询，默认返回空列表，各平台可覆盖 |

| 已实现平台 | 状态 |
|---------|------|
| Shopify | ✅ |
| Amazon | ✅ |
| eBay | ✅ |
| Walmart | ✅ |
| Miva | ✅ |
| Lingxing | ✅ |
| G_ERP | ✅ |
| Tars（内部） | ✅ |
| Cactus（内部） | ✅ |

## IQueryOrderService 之外的 AI Tool 查询能力

除标准订单查询外，Controller 层还封装了以下三方 API 查询，可作为 AI Tool 调用：

### 物流追踪查询

| 平台 | 控制器 | 主要能力 | 备注 |
|------|--------|---------|------|
| Track17 | `Track17ApiController` | `queryTracking(trackingNo)`、`queryTrackingByPollingCarrier(carrier)` | 追踪状态、承运商、送达信息 |
| AfterShip | `AfterShipController` | `getTracking(trackingNo)` | 物流轨迹查询 |

### 产品 / SKU 查询

| 平台 | 能力 | 备注 |
|------|------|------|
| Shopify | 产品详情（GraphQL Admin API） | `ShopifyGraphQLClient.getProductInfo()` |
| Amazon | 商品 listing | `AmazonSpApiClient.getListingsItem(sellerId, sku)` |
| eBay | 商品搜索 + 详情 | `EbayBrowseApiClient`，内置 Guava 本地缓存 |
| Eccang | SKU 产品信息 | `EccangController.getProductInfo(sku)` |
| Lingxing | 产品列表 | `LingxingAppClient.getProducts()` |

### 退款 / 售后查询

| 平台 | 能力 | 备注 |
|------|------|------|
| JackYun | 退款单查询 | `JackYunAppClient.getRefund(tradeRefundGetReq)` |
| Eccang | 创建/查询 RMA 单 | `EccangController.createRmaOrder()` |

### CRM / 工单平台通用查询（Salesforce）

| 能力 | 说明 |
|------|------|
| SOQL 通用查询 | `SalesforceClient.executeQuery(soql)` — 支持原始 SOQL 或结构化查询 |
| 标准对象查询 | Accounts、Contacts、Cases、Leads、Opportunities |
| 自定义对象查询 | 按租户配置支持任意 Custom Object |

### 自定义 API 集成（CustomApiClient）

| 能力 | 说明 |
|------|------|
| 动态 API 调用 | `CustomApiClient` — 用户自定义 API 端点，由 Intelli 代理调用 |
| 低层 HTTP 客户端 | `ApiHttpClient` — 底层出站 HTTP，供自定义集成使用 |

---

## Livechat → 三方工单同步

Livechat 会话结束后，将对话记录同步写入三方工单系统。

| 能力 | 状态 | 备注 |
|------|------|------|
| Livechat 会话 → Zendesk 工单 | ✅ | `ZeluLivechatService`，AI 全程处理 → 创建已解决工单；转人工无回复 → 特殊标记 |
| 自定义字段映射（Zendesk Custom Fields） | ✅ | 支持按租户配置订单号、SKU、问题类型等字段映射 |

## 语音通话 → 三方工单同步（VoiceTicketSyncEngine）

语音通话结束后，将通话记录自动同步到三方工单系统。

| 目标系统 | 状态 | 备注 |
|---------|------|------|
| Cactus（内部） | ✅ | `CactusVoiceTicketSyncHandler` |
| Tars（内部） | ✅ | `TarsVoiceTicketSyncHandler` |
| Zendesk | ✅ | `ZendeskVoiceTicketSyncHandler` |
| Freshdesk | ✅ | 已注册，handler 存在 |

---

## 集成验收要求

> 适用于所有新接入平台。单元测试 + 代码 Review 不构成完整验收，**必须完成 E2E 测试后方可视为交付**。

### 验收层次

| 层次 | 内容 | 时机 |
|------|------|------|
| 单元测试 | `XxxTicketPluginTest`（无凭证，测 parseWebhook / lockKey 等纯逻辑） | 代码合并前，CI 自动执行 |
| API 连通性测试 | `XxxClientTest`（去掉 `@Ignore`，填入真实凭证），确认 CRUD 操作可达 | 代码合并前，需真实账号手动执行 |
| E2E 端对端测试 | 完整链路：触发三方事件 → Intelli 处理 → AI 回复出现在三方平台 UI | 上线前，在 staging 环境手动执行 |

### 工单 AI 回复 E2E Checklist

- [ ] 在 Intelli 前端完成授权，获取 webhook URL
- [ ] 在三方平台配置 webhook URL（或手动创建 Rule/Trigger），指向 staging 环境
- [ ] `XxxClientTest.testCredentials()` 返回 true
- [ ] `XxxClientTest.testGetMessages()` 能拉取测试工单的消息
- [ ] `XxxClientTest.testSendReply()` 回复在三方平台界面可见
- [ ] `XxxClientTest.testAddTag()` 标签在三方平台界面可见
- [ ] 创建真实工单 → AI 回复出现在工单中 → `shulex_ai_replied` 标签被打上

### 注意事项

- `XxxClientTest` 中的 `@Ignore` 仅防止 CI 误触，E2E 时必须去掉并填入真实凭证
- E2E 测试账号应与生产账号隔离，使用专用 test ticket 避免影响真实数据
