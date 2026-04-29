# Intelli 系统能力

> 最后更新: 2026-04-20（新增：form-encoded v1 API 约定、sendReply md2html 说明；修复 webhook URL 示例 LIVEAGENT → LIVE_AGENT）

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
- [ ] **`XxxTicketPlugin` 覆盖 `buildTicketConfig()`**（ChannelAuth 平台必须）：`tarsChannelId = channelAuth.getId()`，`touchPoint = ChannelTypeEnum.XXX.getValue()`，并将 metadata 字段手动映射到 `TicketConfig`。不覆盖则引擎用 JSON 直接解析 metadata 为 `TicketConfig`，但 `TicketMetadata.channelId` ≠ `TicketConfig.tarsChannelId`（字段名不同），导致 `tarsChannelId = null`，Tars 报 `channelId is required`。参考 `LineTicketPlugin.buildTicketConfig()`
- [ ] **`platformId()` 必须 = `ExternKeySourceEnum.{PLATFORM}.name()`**（如 `ExternKeySourceEnum.LIVE_AGENT` → `"LIVE_AGENT"`，不能写 `"LIVEAGENT"`）。不一致时 Tars callback 会路由到 V1 路径，抛 `"原始工单信息不存在"`。
- [ ] **`auth()` 保存时自动填充 botId**：调用 `gptBotFeign.getBots(xToken)`，取 `bots.get(0).getId()` 写入 metadata。不填则 Tars `AiReplyNode` 看到 `botId=null`，`context=false`，静默跳过 AI 回复，无任何 ERROR 日志。

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
| `sendReply()` | ✅ | 发送 AI 回复。**Tars 返回的 AI 内容是 Markdown**，若目标平台渲染 HTML（如 LiveAgent `is_html_message=Y`），需在 `TicketOperations.sendReply()` 中调用 `TextUtil.md2html(reply.getTextContent())` 转换后再发送。纯文本平台可直接用 `reply.getTextContent()`。 |
| `sendHumanReply()` | ✅ | 默认回退到 sendReply，富媒体平台可覆盖 |
| `applyTags()` | ✅ | 批量打标签 |
| `lockKey()` | ✅ | 幂等锁 key，可平台自定义 |

### ThirdPartyApiClient：form-encoded v1 API 处理

部分平台（如 LiveAgent v1 `/api/conversations/`）写接口要求 `application/x-www-form-urlencoded`，而 `ThirdPartyApiClient.httpRequestBuilder()` 默认设 JSON body。

**解决方式**：在客户端类覆盖 `customAttributeSetting()`，将 JSON 字段转为 form 参数，并**显式覆盖 Content-Type 头**：

```java
@Override
public void customAttributeSetting(HttpRequest request, ChannelAuthDO channelAuth, Object data) {
    String url = request.getUrl();
    if (data == null || url == null || !url.contains("/api/conversations/")) {
        return;
    }
    Map<String, Object> params = JSON.parseObject(JSON.toJSONString(data));
    params.forEach((k, v) -> {
        if (v != null) request.form(k, v.toString());
    });
    // ⚠️ 必须显式覆盖：Hutool form() 清除 this.body 字符串，但不修改 Content-Type 头
    // body(String) 已将 Content-Type 设为 application/json，必须手动纠正
    request.header("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8", true);
}
```

参考实现：`LiveAgentClient.customAttributeSetting()`



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
| CustomTicket | Ticket（HTTP 工单系统）| ✅ |

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

## Tars AI 回复架构

Intelli 通过调用 Tars（独立服务）生成 AI 回复，再由 Tars 回调 Intelli 完成投递。

### 整体数据流

```
三方平台 webhook
    ↓
Intelli WebhookDispatchController
    ↓
TicketEngine V2（TicketPlatformPlugin → TicketOperations）
    ↓
Tars API（创建工单 + 异步 AI 处理）
    ↓
Tars botReplyCallbackApiFeign.botReplyCallback()
    ↓
Intelli TicketOperations.sendReply()（实际投递）
```

### Tars bizType 两大类型

| 类型 | 适用平台 | 回复投递方式 | 扩展点基类 |
|------|---------|-----------|----------|
| **邮件型** | Email / Amazon / Shopify / Walmart 等 | Tars 直接发 SMTP/SES 邮件 | `AbstractEmailDeliveryResponseExtPt` |
| **Inbox 型** | LINE / TikTok / LiveAgent 等 | Tars 回调 Intelli，Intelli 调平台 API | `AbstractInboxDeliveryResponseExtPt` |

**新接入的 Ticket 类帮助台平台（如 LiveAgent）应使用 Inbox 型**。

### 新平台在 Tars 的注册要求

1. **`ChannelAuthTypeEnum` 新增枚举值**  
   `value` 必须与 Intelli `ChannelTypeEnum` 的值完全一致（如 Intelli 是 `"live_agent"`，Tars 也必须是 `"live_agent"`）

2. **新建 `{Platform}BizConstants`**  
   `BIZ_ID_XXX = "{platform}"` （小写，与 ChannelTypeEnum value 一致）

3. **`BizScenarioFactory` 两个方法都必须新增路由 case**  
   ⚠️ **`createByTicket()` 和 `createByChannelType()` 都要加**，缺任何一个都会触发 NPE：
   - `createByTicket()` — Tars 内部工单回复路由（如 AI 完成后查工单）
   - `createByChannelType()` — Inbox 创单路由（Intelli 调 `POST /service/inbox/create` 时走这里）
   ```java
   case LIVEAGENT:
       bizType = {Platform}BizConstants.BIZ_ID_XXX;
       break;
   ```

4. **Create 阶段扩展点**（参考 LINE，继承 `AbstractInbox*` 基类）：
   - `FindChannelAuthExtPt` / `FindOrCreateCustomerExtPt` / `BuildMessageExtPt`
   - `SubjectExtPt` / `CheckCanCreateExtPt` / `NewOrReopenTicketExtPt` / `SaveDataExtPt`
   - `FindExistTicketExtPt` — **必须按 externalId 精确匹配**，不使用时间窗口合并
     （LINE 使用的 `AbstractSettingMergeFindExistTicketExtPt` 按客户+时间窗口合并，不适合有明确 ticketId 的帮助台平台）

5. **Reply 阶段扩展点**（最关键）：
   ```java
   @Extension(bizId = "{platform}", useCase = USE_CASE_TICKET_REPLY)
   public class {Platform}DeliveryResponseExtPt extends AbstractInboxDeliveryResponseExtPt {
       @Override
       public ExternKeySourceEnum getExternKeySource() {
           return ExternKeySourceEnum.{PLATFORM};  // 告诉 Tars 回调 Intelli 哪个处理器
       }
   }
   ```

### FindExistTicketExtPt 的两种模式对比

| 模式 | 基类 | 适用场景 | 匹配逻辑 |
|------|------|---------|---------|
| 时间窗口合并 | `AbstractSettingMergeFindExistTicketExtPt` | LINE（无持久 ticketId） | 同客户 + 同渠道 + 最近 N 天 |
| 精确匹配 | 直接实现 `FindExistTicketExtPt` | 帮助台平台（有 ticketId） | `ticketQueryService.findByExternalId(accountId, externalId)` |

### Webhook URL 安全设计（防 IDOR）

**禁止用纯数字 channelId 当 webhook token**——枚举攻击可触发别人 channel 的 queryUrl/replyUrl，并在受害者侧消耗 AI 推理配额。

| ❌ 错误 | ✅ 正确 |
|------|------|
| `/v2/webhook/{PLATFORM}/{numericChannelId}` | `/v2/webhook/{PLATFORM}/{xToken}/{channelId}` |

实现要点：
- `xToken` 从 `ChannelUtil.getApiKey(tenantId, userId)` 取（UUID 格式不可枚举）
- `AbstractChannelAuthController.getWebhookUrl` 子类必须 `@Override` 用 xToken/{channelId} 格式
- `AbstractChatChannelPlugin.resolveCredential` / `AbstractTicketSystemPlugin.resolveCredential` 已移除"纯数字 token → ChannelAuth 直查"的旧路径，必须经 `apiKeyService.getApiKeyByToken` 校验 `channelAuth.accountId == apiKey.tenantId`

### channelAuth metadata 字段约定（botId + xToken）

`TicketProcessingEngine.buildInboxCreateRequest` 从 `TicketConfig` 读取 `botId/xToken` 构建 `aiSetting{aiOpened, botId, token}`。channelAuth 创建时（`doAuth`）必须显式：

```java
String xToken = ChannelUtil.getApiKey(tenantId, CactusUtil.getUserId());
metadata.setXToken(xToken);
List<GetBotResponse> bots = gptBotFeign.getBots(xToken);
if (bots != null && !bots.isEmpty()) {
    metadata.setBotId(bots.get(0).getId());        // 取首个 bot 当默认
}
ChannelAuthDO ca = new ChannelAuthDO();
ca.setBotId(defaultBotId);                          // 同时写到 ChannelAuthDO.bot_id 列
ca.setMetadata(JSON.toJSONString(metadata));
```

**忘记这步的症状**：tars 端 `ApiIntegrationGatewayImpl#getFieldMapping/isFillFieldsApiEnabled` 报 `tenantId=xxx, botId=null`，AI 字段抽取 skip。

### buildTicketConfig 向后兼容 fallback

`AbstractChannelAuthPlugin.buildTicketConfig` 提供老数据兼容：metadata JSON 缺 `botId/xToken` 时降级用 `ChannelAuthDO.bot_id` 列 / `ApiKeyService.getApiKeys(accountId)`。新接入平台**必须依赖正确的 `doAuth` 写 metadata**，fallback 是兜底，不是设计目标。

### Tars view 创建时机

新平台 channel 授权完成后必须调 `ticketViewApi.processChannel` 让 tars 创建工单视图，否则 tars 工单列表里看不到该 channel：

| 用户类型 | 触发点 | 调用方 |
|---------|------|------|
| SLG | controller `createChannel` super 调用之后 | `CustomTicketChannelController.createChannel` 等 |
| PLG | `PersonaCreatedEvent` 处理 | `PlgPersonaService.createChannelViews` |

`tars TicketViewServiceImpl.channelCreteView` 按 `channelType.kind` 路由。**邮件型工单系统**（如 LiveAgent，kind=EMAIL）走 `emailChannelCreteView`；**HTTP 工单系统**（如 CustomTicket，虽然 kind=EMAIL）应显式走 `otherChannelCreteView` 跳过 emailExclude 过滤。

### Operations HTTP 调用统一走 ThirdPartyApiClient

平台插件的 `TicketOperations` 实现里调用第三方 HTTP API 时，**不要直接用 `cn.hutool.HttpRequest`**，应通过 `com.shulex.intelli.intergration.standard.client.ThirdPartyApiClient.sendRequest()`：
- 自带重试（指数退避，4 次）
- 统一日志格式
- 异常转 `BusinessException`

子类化 `ThirdPartyApiClient<AuthContext>` 提供 `getBaseUrl/addAuthorization`，作为 `@Component` 注入到 plugin，再传给 operations。参考 `intelli-ticket-customticket/CustomTicketHttpClient`。

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

---

## 前端集成约定（shulex-smart-service）

### 仓库与目录结构

前端集成代码位于独立仓库 **shulex-smart-service**。

```
src/
  pages/integration/
    Channel/
      index.tsx               ← 平台路由 (switch case)
      AuthPageScaffold/       ← 全页面布局组件（所有新平台使用）
      mod/
        {Platform}Auth/       ← 新平台目录，如 LiveAgentAuth/
          index.tsx            ← 主页面（AuthPageScaffold 包装）
          {Platform}ConnectionDrawer.tsx    ← 授权表单
          {Platform}TicketConfigDrawer.tsx  ← 功能设置（Agent / 处理范围）
          {Platform}WebhookGuideDrawer.tsx  ← 手工操作引导
    index.tsx                 ← 平台卡片列表
  services/
    integration.ts            ← Channel 类型定义 + API 函数
```

### 添加新平台需修改的文件（3 处）

| 文件 | 变更内容 |
|------|---------|
| `src/services/integration.ts` | 1. `Channel` 联合类型新增 `'LIVE_AGENT'`（格式：大写+下划线）<br>2. 追加平台对应的 API 函数（认证/查询 Agent/读写配置/Webhook URL，约 4–6 个）|
| `src/pages/integration/Channel/index.tsx` | 1. import 新 `{Platform}Auth` 组件<br>2. `openChannel` switch 新增 `case 'LiveAgent': return <{Platform}Auth />` |
| `src/pages/integration/index.tsx` | 平台卡片数组新增条目（title, content, icon, nav 路径 `/integration/channel?type=LiveAgent`）|

### API 端点命名约定

```
POST   /api_v2/intelli/{platform}/auth          ← 授权（创建/更新 ChannelAuth）
DELETE /api_v2/intelli/{platform}/auth          ← 撤销授权（不可用 cancelChannel 通用接口，后者走 ExternKey 表）
GET    /api_v2/intelli/{platform}/agents        ← 获取 Agent 列表
GET    /api_v2/intelli/{platform}/setting       ← 读取配置
POST   /api_v2/intelli/{platform}/setting       ← 保存配置
GET    /api_v2/intelli/{platform}/webhook-url   ← 获取 Webhook URL（+ body 模板）
```

`{platform}` 为小写，如 `liveagent`。

> ⚠️ **撤销授权必须实现专用 `DELETE /auth` 端点**，不能复用 `cancelChannel`（`DELETE /api_v2/intelli/channel`）。`cancelChannel` 内部走 ExternKey 表，而新平台用 ChannelAuthDO，会抛 `No enum constant ExternKeySourceEnum.{PLATFORM}` 异常。

### `getSetting()` 响应必须包含 `authed` 布尔字段

前端依赖 `setting.authed` 判断是否已授权。**不能**仅靠字段非空来判断，因为未授权时接口也会返回 200（含空对象）。

```java
// 标准 SettingResponse 结构
@Data
public static class SettingResponse {
    private boolean authed;   // ← 必须有此字段，未授权时为 false
    private String domain;
    private String agentId;
}

// 未授权时
return ResponseResult.success(new SettingResponse()); // authed=false

// 已授权时
response.setAuthed(true);
response.setDomain(channelAuth.getAppKey());
```

### 所有 Controller 端点必须包 `ResponseResult<T>`

LiveAgent 集成初版遗漏了 `ResponseResult` 包装，导致前端 `res?.data` 为 `undefined`。

```java
// 正确 ✅
public ResponseResult<SettingResponse> getSetting() { ... }

// 错误 ❌（会导致前端 res?.data 为 undefined）
public SettingResponse getSetting() { ... }
```

前端拦截器会自动剥离 `ResponseResult` 外层，组件收到的是 `data` 字段内容。使用 `useRequest` 时如需手动提取，配置 `formatResult: (res) => res?.data`。

### Webhook URL 构建（含 gateway 前缀）

外部 Webhook URL 需加 `/api_v2/intelli` gateway 前缀：

```java
// 正确 ✅
String webhookUrl = webhookBaseUrl + "/api_v2/intelli/v2/webhook/LIVE_AGENT/" + token;

// 错误 ❌（缺少 gateway 前缀，LiveAgent Rules 会打到 404）
String webhookUrl = webhookBaseUrl + "/v2/webhook/LIVE_AGENT/" + token;
```

后端服务本身只暴露 `/v2/webhook/{platform}/{token}`，gateway 在转发时会剥除 `/api_v2/intelli` 前缀。对外展示的 URL（如 `webhook-url` 接口返回值、前端引导文案）必须带完整前缀。

参考 LINE 的实现：`baseUrl.replaceFirst("/line$", "") + "/v2/webhook/LINE/" + xToken`，其中 `baseUrl` 形如 `https://desk-staging.shulex.com/api_v2/intelli/line`。

| 授权模式 | 参考实现 | 说明 |
|---------|---------|------|
| API Key（子域名 + 密钥） | `LiveAgentAuth/` | 最新实现，含 ConnectionDrawer + TicketConfigDrawer + WebhookGuideDrawer |
| API Key（仅密钥） | `FreshDeskAuth/`（参考，路径可能不同）| 无子域名的简化版 |
| OAuth 跳转 | `LineAuth/` | 含子域名输入 + OAuth 跳转流程 |

---

## Maven 子模块约定（intelli-ticket-{platform}）

### 模块位置

新平台 TicketPlugin 模块位于：

```
shulex-intelli-ticket/
  intelli-ticket-{platform}/     ← 新建此目录
    pom.xml
    src/main/java/com/shulex/intelli/ticket/{platform}/
      {Platform}TicketPlugin.java
      {Platform}TicketOperations.java
      {Platform}ChannelAuthCredential.java
      {Platform}PlatformContext.java          ← 如需携带额外字段
      {Platform}TicketAutoConfiguration.java
    src/main/resources/META-INF/spring.factories
    src/test/java/com/shulex/intelli/ticket/{platform}/
      {Platform}TicketPluginTest.java
```

### pom.xml 依赖结构

```xml
<parent>
    <groupId>com.shulex</groupId>
    <artifactId>shulex-intelli-ticket</artifactId>
    <version>1.0-SNAPSHOT</version>
</parent>

<dependencies>
    <!-- 核心 SPI 接口 -->
    <dependency>
        <groupId>com.shulex</groupId>
        <artifactId>intelli-ticket-core</artifactId>
        <version>${project.version}</version>
    </dependency>
    <!-- HTTP Client（已有实现复用）-->
    <dependency>
        <groupId>com.shulex</groupId>
        <artifactId>shulex-intelli-integration</artifactId>
        <version>${project.version}</version>
        <scope>provided</scope>
    </dependency>
    <!-- AutoConfiguration 基础设施 -->
    <dependency>
        <groupId>com.shulex</groupId>
        <artifactId>intelli-ticket-spring-boot-starter</artifactId>
        <version>${project.version}</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

### 两处必须手动添加（常见遗漏）

**1. 父模块 `shulex-intelli-ticket/pom.xml` 的 `<modules>` 块**

```xml
<modules>
    <module>intelli-ticket-core</module>
    <module>intelli-ticket-spring-boot-starter</module>
    <module>intelli-ticket-line</module>
    <module>intelli-ticket-liveagent</module>
    <module>intelli-ticket-{platform}</module>   ← 新增
</modules>
```

**2. `src/main/resources/META-INF/spring.factories`**

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.shulex.intelli.ticket.{platform}.{Platform}TicketAutoConfiguration
```

> ⚠️ 这两处都不会报编译错误，但缺少任一项，Plugin 不会被 Spring 加载。

**3. `shulex-intelli-api/pom.xml` 的 `<dependencies>` 块**（最容易遗漏）

```xml
<dependency>
    <groupId>com.shulex</groupId>
    <artifactId>intelli-ticket-{platform}</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>
```

> ⚠️ 缺少此依赖时，Plugin JAR 不在 api 模块 classpath 中，`spring.factories` 永远不会被扫描，启动日志看不到 `Registered ticket platform plugin: {PLATFORM}`，webhook 请求返回 `unsupported platform`。这是 LiveAgent 集成测试时遇到的第一个问题（2026-04-15）。

---

## 测试规范

### 单元测试：`{Platform}TicketPluginTest`

**位置**：`intelli-ticket-{platform}/src/test/java/.../{Platform}TicketPluginTest.java`

**原则**：无需任何凭证和网络，只测 `parseWebhook` 等纯逻辑。用 `null` 依赖初始化 Plugin。

**必须覆盖的测试用例**：

| 测试方法 | 验证内容 |
|---------|---------|
| `testPlatformId()` | `plugin.platformId()` 返回正确枚举值字符串 |
| `testParseWebhook_success()` | 正常 payload → `shouldProcess=true`，ticketId / tenantId / platformId / platformContext 字段均正确 |
| `testParseWebhook_missingTicketId_skips()` | 缺少 ticketId → `shouldProcess=false` |
| `testParseWebhook_malformedJson_skips()` | 非法 JSON → `shouldProcess=false`（不抛异常）|
| `testExtractCredentialKey()` | 给定 token 字符串 → `CredentialKey` 的 platformId 和 rawToken 正确 |
| `testLockKey()` | `lockKey()` 格式符合 `ticket:{platform}:{conversationId}` 规范 |

### 集成测试（API 连通性）：`{Platform}ClientTest`

> ⚠️ **执行时机：写 `TicketOperations` 之前，不是之后。**  
> 三方文档经常省略关键细节（body 格式、必填参数、特殊行为），靠文档推断再到 staging 验证会放大反馈周期。先跑 ClientTest 确认实际 API 行为，再写 TicketOperations。

**位置**：`shulex-intelli-integration/src/test/java/.../{Platform}ClientTest.java`

**原则**：
- 所有方法加 `@Ignore`，防止 CI 运行
- 凭证通过类顶部常量填写，不要 hardcode 到方法体
- **写操作**（sendReply / addTag）加 `// WARNING: creates real data` 注释，使用专用测试工单

**标准测试方法**：

| 方法 | 类型 | 内容 |
|------|------|------|
| `testCredentials()` | 读 | 验证 API Key 有效，返回 `true` |
| `testGetAgents()` | 读 | 拉取 Agent 列表，断言非空 |
| `testGetMessages()` | 读 | 拉取测试工单消息，断言非空 |
| `testGetTags()` | 读 | 拉取标签，允许为空，不抛异常即通过 |
| `testSendReply()` | **写** | 向测试工单发送固定文案 `"[Shulex Intelli test reply — please ignore]"` |
| `testAddTag()` | **写** | 向测试工单打标签 `shulex_intelli_test` |

**运行前提**：去掉 `@Ignore`，填写 `TEST_DOMAIN / TEST_API_KEY / TEST_TICKET_ID` 常量。

### E2E 端对端测试

**前提条件**（缺一不可）：
- 可公网访问的 Intelli **staging 环境**（本地环境无法接收 webhook）
- 三方平台的**测试账号**（与生产账号隔离）
- 在三方平台后台已配置 webhook URL 指向 staging

**验证顺序**：

```
Step 1: 授权验证
  → 在 Intelli 前端打开授权页，填入测试账号凭证，点击"连接"
  → 确认前端显示"已授权"状态
  → 获取前端展示的 Webhook URL

Step 2: Webhook 配置
  → 在三方平台后台配置 Webhook URL（或创建 Automation Rule），
    指向 Step 1 获取的 URL
  → 若平台需要手动配置 body 模板，使用 Manual Guidance 页面的模板

Step 3: API 连通性（运行 ClientTest）
  → 去掉 @Ignore，填入测试凭证，运行：
    mvn test -Dtest={Platform}ClientTest -pl shulex-intelli-integration
  → testCredentials() 必须返回 true
  → testGetMessages() 必须拉到消息（工单 TEST_TICKET_ID 需有历史消息）

Step 4: 完整链路验证
  → 在三方平台创建一条测试工单（或回复已有工单触发 webhook）
  → 查看 staging 日志确认 webhook 被接收：
    grep "LIVE_AGENT\|liveagent" /logs/intelli.log
  → 等待 AI 自动回复（通常 10–30 秒）
  → 在三方平台工单界面确认：
    ✅ AI 回复内容出现
    ✅ 工单被打上 shulex_ai_replied 标签
```

**常见失败原因**：
- Webhook 未收到 → 检查三方平台 Rule 是否触发、URL 是否正确、防火墙是否放行
- AI 回复未出现 → 查日志排查 resolveCredential() 是否找到 ChannelAuth 记录
- 标签未打上 → 查日志确认 applyTags() 没有抛异常
