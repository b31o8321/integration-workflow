# Voice 通话链路

> 适用场景：接入语音通话功能，理解通话记录如何转为工单。

## 整体架构（事件驱动 + 策略模式）

```
Kafka: voice-transcripts-produced-topic
  ↓
VoiceTranscriptConsumer（校验 + 委托）
  ↓
VoiceTicketSyncEngine（编排：路由 → 查通话详情 → 构建上下文 → 委托 Handler）
  ↓
VoiceTicketSystemResolver（路由决策）
  ↓
Handler 实现（TarsVoiceTicketSyncHandler / CactusVoiceTicketSyncHandler / ZendeskVoiceTicketSyncHandler）
```

## 关键文件路径

| 文件 | 路径 |
|------|------|
| Kafka 消费者 | `shulex-intelli-api/.../mq/consumer/VoiceTranscriptConsumer.java` |
| 同步引擎 | `shulex-intelli-api/.../service/voice/VoiceTicketSyncEngine.java` |
| 路由决策 | `shulex-intelli-api/.../service/voice/VoiceTicketSystemResolver.java` |
| Handler 接口 | `shulex-intelli-api/.../service/voice/VoiceTicketSyncHandler.java` |

## callType 字段映射规则

| callType | customer.phone 取自 | ChannelAuth sellerId 取自 | phoneType |
|----------|--------------------|--------------------------|----|
| webCall | "web_number"（固定） | "web_number"（固定） | INBOUND |
| inboundPhoneCall | callerNumber（客户主叫） | phoneNumber（AI 被叫号码） | INBOUND |
| outboundPhoneCall | phoneNumber（客户被叫） | callerNumber（AI 外呼号码） | OUTBOUND |

## 路由规则（优先级）

1. `callType == outboundPhoneCall` → PLG 租户返回 TARS，否则 null（不处理）
2. Anker 租户 + 匹配 agentId → CACTUS
3. 租户有 Zendesk ExternKey 且开启 voiceSync → ZENDESK
4. PLG 租户 → TARS
5. 其他 → null（不处理）

## ChannelAuth 查找/创建（Tars Handler）

- webCall：按 sellerId="web_number" + personaId 查
- inbound：按 sellerId=phoneNumber + personaId 查，查不到返回 null（error log）
- outbound：按 sellerId=callerNumber + personaId 查，**查不到自动创建**
