# 三方数据同步 Job 引擎链路

> 适用场景：接入电商/ERP 平台数据同步（订单、商品等），理解 Job 引擎运作机制。

## 整体架构（模板方法 + 策略模式）

```
XXL-Job 调度器
  ↓
Sync{Platform}Job（继承 SyncExecutionEngine）
  ↓ executeIncrementalSync() / executeHistorySync() / executeManualSync()
SyncExecutionEngine（通用引擎）
  → getValidChannelAuths()（从 ISyncService 获取）
  → 按租户分组 + 轮询排序（租户公平性）
  → tryLock(channelAuth)（Redisson 分布式锁，Key 含 channelAuthId）
  → 查询/更新 JobParams（断点续传）
  → 计算同步时间窗口（支持动态窗口）
  → executeSync(context)（委托 ISyncService）
  → 更新 JobParams 时间戳
  ↓
{Platform}SyncService（实现 ISyncService）
  → 调用三方 API 拉取数据 → 数据转换 → saveOrUpdateBatch()
```

## 同步模式

| 模式 | 触发 | 时间窗口 |
|------|------|---------|
| 增量同步 | 每30分钟 | 最近24小时 |
| 历史同步 | 手动/每日 | 365天，7天窗口分批，支持断点续传 |
| 手动同步 | 按需 | 指定 channelAuthIds + 时间范围 |

## 新增平台步骤

1. 实现 `ISyncService`：`getValidChannelAuths()`、`executeSync()`、`generateTraceId()`
2. 创建 `Sync{Platform}Job extends SyncExecutionEngine`，注入并实现三个 `@XxlJob` 方法（增量/历史/手动）
3. 在 XXL-Job 后台配置三个任务

## 分布式锁 Key 格式

`intelli:sync_lock:{platform}:{syncType}:{accountId}:{channelAuthId}`

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 多实例重复同步 | 无锁竞态 | Redisson 分布式锁（含 channelAuthId） |
| 历史同步中断无法恢复 | JobParams 未更新 | 每批次后立即更新 node 字段 |
| 大租户阻塞小租户 | 线程池被占满 | 租户轮询排序机制 |
| 时间戳格式错误 | 时区混用 | 统一 ISO8601 + UTC，用 `LocalDateTimeUtils.dateTime2Iso8601Str()` |
