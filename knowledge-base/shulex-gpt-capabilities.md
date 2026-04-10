# shulex_gpt AI 能力

> 最后更新: 2026-04-10（by intelli:update-kb）

## 语音处理

### Voice Provider

| Provider | 常量 | 用途 |
|---------|------|------|
| VAPI | `VoiceProviderConst.VAPI` | 主要语音通话 provider（VoiceSourceEnum: VAPI） |
| Deepgram | `VoiceProviderConst.DEEPGRAM` | ASR 引擎 |
| MiniMax | `VoiceProviderConst.MINIMAX` / `VoiceProvider.MINIMAX` | TTS / 中文语音合成 |
| OpenAI | `VoiceProvider.OPENAI` | TTS |
| Inworld | `VoiceProviderConst.INWORLD` | 游戏/角色语音 |
| Twilio | `TwilioService` | 电话通话集成（PSTN） |

### 语音对话上下文（VoiceChatContext）

| 字段 | 说明 |
|------|------|
| `currentTurn` | 当前对话轮次 |
| `assistant` | VoiceAssistantDTO 配置 |
| `algVoiceData` | 算法侧语音数据 |
| `chatStream` | `Consumer<AzureChatCompletionResponse>` 流式回调 |
| `request` | VapiChatRequest 请求参数 |
| `traceId` | 请求链路追踪 ID |

### 实时流式输出

- 使用 SSE（Server-Sent Events）格式，与 OpenAI streaming 兼容
- `AzureChatCompletionResponse.sseChunk()` 推送 delta（内容、tool calls、finish reason）
- 支持多选项（`List<ChoicesItem>`），finishReason: `stop` / `length` / `tool_calls`

---

## VAPI 语音通话能力（NEW）

### 通话类型（VapiCallType）

| 类型 | 说明 |
|------|------|
| `webCall` | 网页语音通话 |
| `inboundPhoneCall` | 电话拨入（呼入） |
| `outboundPhoneCall` | 系统外呼 |

### Webhook 接收

- **入口：** `POST /api/webhooks/vapi/outbound`（`VapiWebhookController.receive()`）
- **处理：** `VapiWebhookServiceImpl.handlePayload()`
  - 事件类型：`status-update`（过程状态）、`end-of-call-report`（通话结束）
  - 幂等键：`callId:eventType:status:endedReason`，持久化到 `vapi_webhook_event` 表
  - 状态流：`queued → ringing → in-progress → ended`

### 通话记录存储（S3）

- 通话结束后 VAPI 将 JSONL 文件推送至 S3：`vapi/{callId}-xxx.jsonl.gz`
- AWS SNS 触发 `SnsHookServiceImpl`，读取后转存为：`plg/vapi/call/{callId}.json`
- 工具类 `VoiceS3Util` 提供：
  - `getPreSignedUrl(key, expire)` — 生成临时访问 URL
  - `getStr(key)` — 读取 JSON 文本内容
  - `putWithContentType(bucket, key, body, contentType)` — 上传文件

### 通话记录关键字段（VapiCallLog / VoiceTranscriptDTO）

| 字段 | 说明 |
|------|------|
| `id` / `chatId` | VAPI 会话 ID |
| `type` | 通话类型（见上表） |
| `startedAt` / `endedAt` | 开始/结束时间 |
| `callDuration` | 通话时长（秒） |
| `transcript` | 对话文本记录 |
| `recordingUrl` | 录音文件 URL |
| `stereoRecordingUrl` | 立体声录音 URL |
| `summary` | 通话摘要 |
| `endedReason` | 结束原因（来自 VAPI） |
| `customerNumber` | 客户号码 |
| `transcriptUri` | S3 相对路径键 |

### 通话结束原因（finalDisposition）

| 值 | 说明 |
|----|------|
| `answered_completed` | 接通并正常结束 |
| `no_answer` | 无人接听 |
| `busy` | 被叫占线 |
| `invalid_number` | 号码无效 |
| `rejected` | 被叫拒接 |
| `system_error` | 系统异常 |

### 与 Intelli 的同步机制

通话记录落库后，通过 **Kafka** 异步通知 Intelli 创建工单/Inbox：

- **Topic：** `voice-transcripts-produced-topic`
- **消息类：** `VoiceTranscriptProducedMessage`

关键字段：

| 字段 | 说明 |
|------|------|
| `tenantId` | 租户 ID |
| `chatId` | VAPI 通话 ID |
| `eventType` | `finish`（通话完成）/ `startRing`（开始振铃） |
| `channel` | `plg`（plugin）/ `slg` |
| `metadata.callType` | 通话类型 |
| `metadata.callDuration` | 通话时长（秒） |
| `metadata.callerNumber` | 来电号码 |
| `metadata.phoneNumber` | 被呼号码 |
| `metadata.batchNumber` | 外呼批次编号（外呼场景） |
| `metadata.batchName` | 外呼批次名称（外呼场景） |

Intelli 消费此消息后创建语音通话工单，通话记录（录音 URL、转录文本、时长）通过 S3 预签名 URL 可访问。

---

## Tool Call / Function Call

### 调用模式（AgentCallToolModeEnum）

| 模式 | 值 | 说明 |
|------|----|------|
| `FreeDecision` | `null` | 模型自由决定是否调用 tool |
| `ConstrainedDecision` | `"required"` | 强制调用 tool（OpenAI `tool_choice: required`） |

### 调用格式（OpenAI 兼容）

`ToolCall` 结构：`id` / `name` / `args（Map）` / `type="function"` / `index`（多工具并发）

同时保留 `FunctionCall`（`name` + `arguments` JSON 字符串）用于旧版兼容。

### 内置 Tool 类型（ToolType）

| Tool | 类型 | 说明 |
|------|------|------|
| `EMAIL` | 系统 | 发送邮件 |
| `SMS` | 系统 | 发送短信 |
| `GOOGLE_CALENDAR` | toolkit | Google 日历集成 |
| `GOOGLE_SHEET` | toolkit | Google Sheets 集成 |
| `SHOPIFY` | toolkit | Shopify 电商集成 |
| `LOGISTICS_17_TRACK` | 系统 | 17Track 物流查询 |
| `RETRIEVE_KNOWLEDGE` | 系统 | 知识库检索（RAG） |
| `TRANSFER_TO_HUMAN` | 系统 | 转人工 |
| `EXTERNAL_HTTP` | 用户自定义 | 自定义 HTTP 工具 |

工具分来源：`ToolSource.SYSTEM`（系统内置）和 `ToolSource.MANUAL`（用户自定义）

---

## 意图识别 / NLU

### 接口

`IntentRecognizeRequest` → `IntentRecognizeResponse`（`List<Intent>`）

| 字段 | 说明 |
|------|------|
| `messages` | 完整对话历史 |
| `touchPoint` | 交互触点 |
| `serviceId` | `ServiceIdEnum` 业务标识 |
| `model` | 指定 NLU 模型（默认 `gpt-4o-mini`） |
| `excludeSub` | 是否排除子意图 |

### Intent 结构

| 字段 | 说明 |
|------|------|
| `id` | 意图 ID |
| `name` | 意图名称 |
| `i18n` | 国际化文本 |
| `collects` | 需采集的实体字段列表 |

意图可通过 `ClassifierIntent`（含 `name`、`description`、`examples`）自定义训练，来源标记为 `TagSourceEnum`（系统 / 用户自定义）。

---

## 对话状态管理（ChatContext）

| 字段 | 说明 |
|------|------|
| `turn` | 当前轮次（int，自增） |
| `language` | 检测到的语言（BotLanguageEnum） |
| `intents` | 本轮识别到的意图列表 |
| `toolCalls` | 本轮调用的工具列表 |
| `collected` | 已采集实体（Map<String, List<Object>>） |
| `collecting` | 当前正在采集的字段 |
| `historyMessages` | 完整对话历史 |
| `retrievedKus` | RAG 检索结果 |
| `byRAG` | 是否通过知识库生成回复 |
| `redLineHits` | 触发的合规红线 |
| `strategyAction` | 当前策略动作 |
| `agentContext` | 多 Agent 上下文 |

---

## LLM 模型支持

### 静态枚举（LLMTypeEnum）

| 模型 | 标识 |
|------|------|
| GPT-3.5 Turbo | `gpt-35-turbo` |
| GPT-4 | `gpt-4` |
| GPT-4o Mini | `gpt-4o-mini` |
| Claude 3 Haiku | `anthropic.claude-3-haiku-20240307-v1:0` |

### 动态配置（PlgModelConfig，读自 Nacos）

| 用途 | 默认模型 |
|------|---------|
| 文本生成 | `gpt-4o` |
| 语音对话 | `gemini-2.5-flash` |
| 意图识别 | `gpt-4o-mini` |
| 翻译 | `gpt-4o-mini` |
| 语言检测 | `gpt-4o-mini` |

> 各模型可按租户配置覆盖，支持多 LLM provider 路由。

---

## 知识库 / RAG

### RetrievedKu（检索知识单元）

| 字段 | 说明 |
|------|------|
| `kuType` | `QA`（问答对）/ `TC`（文本块） |
| `kuSource` | 知识来源分类 |
| `score` | 向量相似度得分 |
| `rerankScore` | 重排序得分 |
| `relevantScore` | 相关性得分 |
| `effect` | 是否实际被引用 |

### 检索配置（ChatContext）

| 参数 | 说明 |
|------|------|
| `crRetrieveMinScore` | 最低检索分阈值 |
| `crRelevantMinScore` | 最低相关性分阈值 |
| `crRelevantKusCount` | 参与评估的 KU 数量 |
| `crUsedKusCount` | 最终使用的 KU 数量 |

### 知识搜索接口

`QaBotPlgApi.searchKnowledgePlg()` 支持三路检索：
- `useQa` — Q&A 问答库
- `useDoc` — 文档库
- `useProduct` — 产品知识库（支持从 Amazon / Shopify 导入）

### 知识检索 Tool

`RetrieveKnowledgeToolExecutor`：输入 `query`，按 `directoryIds` 过滤，返回格式化知识上下文，供 LLM 生成回复。

---

## 多 Agent 编排（MultiAgentGraph）

| 能力 | 说明 |
|------|------|
| Agent 图定义 | `agents`（节点）+ `agentEdges`（有向边）+ `entryAgentId`（入口） |
| Agent 路由 | 基于 tool 执行结果的 `matchStatus` 触发 `actions` 切换目标 Agent |
| 多轮编排 | `BuilderConversationDomainService` 管理跨 Agent 会话 |
| ChatFlow | `ChatFlowService` 支持节点图式对话流程定义 |
| 流式输出 | SSE delta 推送支持多 Agent 场景下的实时输出 |

---

## 多语言支持（BotLanguageEnum）

支持 36+ 语言，含：英语、简体中文、繁体中文、粤语、日语、法语、西班牙语、阿拉伯语、德语、俄语、葡萄牙语、意大利语、韩语、荷兰语、印尼语、土耳其语等。

语言检测：每次对话自动检测（`ChatContext.language`），可被租户配置锁定。
