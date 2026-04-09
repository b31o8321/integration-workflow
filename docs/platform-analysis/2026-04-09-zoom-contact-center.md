# Zoom Contact Center 接入可行性评估

> 分析日期: 2026-04-09
> 分析人: Claude (intelli:analyze)
> 数据来源: https://developers.zoom.us/docs/api/contact-center/
> 业务场景: 美业门店来电 AI 语音接听，消除 miss call，AI 引导预约

---

## 一、结论（PM / 交付用）

| 功能 | 结论 | 说明 |
|------|------|------|
| 工单AI回复 | ❌ 不可行 | 电话客服平台，无工单数据模型，不适用 |
| Livechat对接 | ⚠️ 部分可行（需适配） | `engagement.missed` webhook 可感知漏接；实时语音 AI 接管需 Voice Engine 新链路 |
| 数据同步 | ❌ 不可行 | 非 CRM/预约平台，无订单/预约数据 |
| **AI 语音接入（新）** | ⚠️ 部分可行（需新链路） | 来电路由到 AI 端点需配置 Zoom Virtual Agent / CTI；实时语音处理为新链路 |

### 建议

Zoom CC 的核心集成价值在于**来电 AI 语音接听**，从源头消除 miss call。建议优先实现 AI Voice Engine 新链路（ASR → NLU → TTS + Zenoti 预约 tool），Zoom CC 侧通过 CTI routing 或 Virtual Agent 配置将来电转接到 Intelli AI 端点。工单 AI 回复和数据同步维度均不适用，无需投入。

---

## 二、技术差距分析（研发用）

### 工单AI回复

**可行性：** ❌ 不可行

Zoom CC 是电话客服平台，无 ticket 对象，无消息线程 REST API，无法套用 TicketEngine V2 SPI。不建议实现。

---

### Livechat对接 / AI 语音接入

**可行性：** ⚠️ 部分可行（需新链路设计）

**差距列表：**

- [Blocking → 需新链路] **实时语音 AI 注入** — 公开 API 不支持向通话中注入 AI 语音。需通过 Zoom Virtual Agent（Zoom 原生）或 CTI 集成（SIP/PSTN 层）将来电路由到 Intelli AI Voice Engine。这是整个方案的核心技术挑战。
- [Medium] **无 WebSocket** — 入站事件通过 webhook 推送（`engagement.created`、`engagement.missed`），非实时流。AI Voice Engine 需通过 Zoom Virtual Agent webhook 接收每轮语音输入（ASR 结果），而非 WebSocket 流。
- [Minor, ~0.5天] **Miss call 补救路径** — 若 AI Voice 未能接听（极端情况），`engagement.missed` webhook 仍可触发 GHL SMS 兜底跟进。需实现 webhook adapter。
- [Minor] **无 getSubject / tag 系统** — 对话中无标准 ticket 标签体系；可用 Zenoti 预约 ID 作为会话标识。

**预估工作量：**

| 模块 | 工作量 |
|------|--------|
| Zoom CC CTI / Virtual Agent 路由配置 | 1–2 周（含 Zoom 侧配置与联调） |
| Voice Session Manager（多轮对话状态） | 1–2 周 |
| ASR / TTS 接入（若未有现成模块） | 1–2 周 |
| 预约意图提取 NLU 层 | 1 周 |
| Miss call webhook adapter（兜底） | 0.5 天 |
| **合计** | **4–7 周（含 Zoom 平台联调）** |

---

### 数据同步

**可行性：** ❌ 不可行

平台无订单/预约/商品数据，不适用于 ISyncService。不建议实现。

---

## 三、接入 Checklist（研发用）

### AI 语音接入 Checklist（新链路）

- [ ] 确认 Zoom CC 账户是否开通 Virtual Agent 或 CTI 集成权限
- [ ] 配置 Zoom CC 呼叫流：来电 → 路由到 Intelli AI Voice 端点
- [ ] 实现 Voice Session Manager
  - [ ] 会话创建（对应 `engagement.created` 事件）
  - [ ] 多轮对话状态维护（服务类型 / 日期 / 门店收集进度）
  - [ ] 会话关闭（对应 `engagement.ended` 事件）
  - [ ] 幂等 key：`engagementId`
- [ ] 接入 ASR（语音转文字）
- [ ] 接入 TTS（文字转语音）
- [ ] 实现预约意图提取（NLU）
  - [ ] 识别服务类型
  - [ ] 识别期望日期/时间
  - [ ] 识别门店偏好
- [ ] 实现 Zenoti tool 调用（见 Zenoti checklist）
- [ ] Miss call 兜底：实现 `engagement.missed` webhook adapter → 触发 GHL SMS
  - [ ] 注册 Zoom CC webhook（HMAC-SHA256 验证：`x-zm-signature`）
  - [ ] 解析来电号码（ANI）→ 匹配 GHL 联系人 → 发送 SMS
