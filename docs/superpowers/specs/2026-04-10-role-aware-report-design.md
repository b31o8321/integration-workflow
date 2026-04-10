# Role-Aware Report System — 设计规格

> 日期: 2026-04-10
> 作者: Claude (superpowers:brainstorming)
> 状态: 待实现

---

## 背景

现有 `intelli:report` 将 PM/交付、研发、架构内容混在一个文件中，不同受众需要自己过滤无关内容。目标是让每类用户只看到适合自己身份的报告，其他文档静默生成供后续使用。

---

## 角色系统

### 角色定义

| 角色标识 | 受众 | 对话风格 |
|---------|------|---------|
| `pm` | PM / 交付 | 聚焦结论、工作量、风险；不出现 API 细节 |
| `arch` | 产品 / 架构 | 系统边界、数据流、架构决策；适量技术深度 |
| `dev` | 研发 | 全技术细节、API 端点、差距列表、Checklist |
| `claude` | Claude AI 开发 | 结构化需求规格，为 writing-plans 输入优化 |

### 角色识别时机

- **触发点：** `intelli:analyze` Phase 1 的**第一个问题**
- **形式：** 四选一单选
- **作用域：** 角色确定后贯穿整个分析对话，影响：
  - 后续提问的深度和语言风格
  - 中间结果（check-api、map-arch）的呈现详细程度
  - 最终 report 对话中展示哪份文档

---

## 四份报告文档

### 目录结构

```
docs/platform-analysis/YYYY-MM-DD-{platform-name}/
  pm.md        # PM / 交付版
  arch.md      # 产品 / 架构版
  dev.md       # 研发版
  spec.md      # Claude Spec（writing-plans 输入）
```

独立运行时子目录名与之前保持一致命名规范（lowercase-hyphenated）。

### `pm.md` 内容

- 授权前置条件（仅 MARKETPLACE_APP / CONDITIONAL 时出现）
- 流量灯结论表（✅/⚠️/❌，含一句话说明）
- 建议（2–3 句，优先级 + 实施顺序）
- 工作量汇总表（模块 + 周期，不含技术细节）
- 主要风险点（非技术语言，≤3 条）

### `arch.md` 内容

- 系统边界描述：第三方平台 / Intelli / GPT 各自职责
- 数据流：事件/消息如何在三方间流转
- 关键架构决策点（如：新链路 vs 复用现有引擎、WebSocket vs Webhook）
- 技术前置条件（需要确认的外部依赖）
- 依赖关系（模块间的实现顺序约束）

### `dev.md` 内容

- 授权与接入模式详情（认证类型、endpoint、签名验证）
- 各维度技术差距列表（Minor/Medium/Blocking，含 workaround）
- 预估工作量明细（按子模块）
- 接入 Checklist（可执行条目，含具体 API endpoint）

### `spec.md` 内容（Claude Spec）

- 目标：一句话描述要接入什么、实现什么功能
- 范围：明确包含 / 不包含的功能边界
- 现有接口约束：需实现的 SPI 接口列表（TicketPlatformPlugin、TicketOperations、ISyncService 等）
- 差距列表（仅可行/部分可行项，Blocking 项标注必须解决）
- 验收标准：每个功能维度的完成定义
- 依赖：外部 API 文档链接、需要的凭据/权限

---

## 对话输出规则

报告生成完成后，对话中：

1. **完整展示**当前角色对应的文档内容
2. **仅给路径**列出其余三份，格式：
   ```
   其他报告：
   - 产品/架构版：docs/platform-analysis/.../arch.md
   - 研发版：docs/platform-analysis/.../dev.md
   - Claude Spec：docs/platform-analysis/.../spec.md
   ```

---

## 改动范围

### `skills/analyze/SKILL.md`

- Phase 1 新增第一步：询问用户角色（pm / arch / dev / claude）
- 角色存入分析上下文，影响后续对话深度
- 调用 `intelli:report` 时传递角色

### `skills/report/SKILL.md`

- 输入新增：角色参数（来自 analyze 上下文，或独立调用时从用户获取）
- 独立调用时若无角色，执行前先问一次
- 生成逻辑拆分为四个独立模板块
- 输出到子目录，生成四个文件
- 对话输出按角色展示规则执行

### `skills/flow-analyze/SKILL.md`

- 入口同样询问角色
- 链路模式报告改为四份输出（现为单文件混合）
- 链路模式的 `spec.md` 描述业务链路中各 Step 的实现需求

### 不动的技能

`intelli:check-api`、`intelli:map-arch`、`intelli:update-kb` — 输出格式不变，角色感知只在 analyze 入口和 report 层处理。

---

### `README.md`

需同步更新以下内容：

1. **各角色适用场景** — 现有表格描述"在 Phase N 停止"，改为描述角色识别机制：分析开始时询问角色，对话和报告均按角色定制

2. **报告输出位置** — 路径从单文件改为子目录四文件：
   ```
   docs/platform-analysis/YYYY-MM-DD-{platform-name}/
     pm.md / arch.md / dev.md / spec.md
   ```

3. **Skills 列表** — `intelli:report` 描述从"生成双层可行性报告"改为"生成角色定制的四份报告文档"

---

## 边界与约束

- 角色只问一次，不重复询问
- 四份文档**总是全部生成**，无论角色是什么
- 独立调用 `intelli:report`（不经过 analyze）时，若上下文中无角色，执行前询问一次
- `spec.md` 不包含已判定为 ❌ 不可行的功能（避免 Claude 实现不可行项）
- 现有已生成报告的格式不受影响（本设计只改 skill 文件，不改已有 .md 文件）
