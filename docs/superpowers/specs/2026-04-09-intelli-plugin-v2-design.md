# Intelli Plugin v2 设计文档

**日期:** 2026-04-09
**项目:** integration-workflow
**状态:** 待实现
**背景:** 基于首次三平台分析（Zoom CC / GHL / Zenoti）的复盘，重新设计插件使其支持业务链路验证模式。

---

## 一、问题复盘

当前插件（v1）存在以下核心问题：

1. **平台视角 vs 业务视角**：现有分析固定三维度（工单/Livechat/数据同步），无法回答"这条业务链路能否跑通"的问题。
2. **分析粒度不足**：能力矩阵只到功能级别，缺少具体 API 端点和三方文档链接，研发无法直接使用。
3. **系统能力盲区**：只分析三方平台 API，没有评估 Intelli/shulex_gpt 的现有能力，导致"我方能做什么"无法判断。
4. **插件更新机制脆弱**：修改 skill 文件后不 bump 版本，`/reload-plugins` 不重新拉取，用户拿到的是旧版本。
5. **Phase 1 业务背景收集流于形式**：没有结构化地收集业务目标，导致分析假设偏差（如 Zoom CC 定位错误）。

---

## 二、整体架构

### 新增 / 修改文件

```
skills/
  analyze/SKILL.md          ← 修改：Phase 1 加模式选择（标准 vs 链路）
  flow-analyze/SKILL.md     ← 新增：业务链路验证核心逻辑
  update-kb/SKILL.md        ← 新增：分析代码库，更新 knowledge-base
  report/SKILL.md           ← 修改：支持链路模式报告格式
  check-api/SKILL.md        ← 不变
  map-arch/SKILL.md         ← 不变

knowledge-base/
  README.md                 ← 新增：维护说明
  intelli-capabilities.md   ← 新增：Intelli SPI 接口 + 已支持平台
  shulex-gpt-capabilities.md ← 新增：AI 能力清单（语音/NLU/工具调用等）

install.sh                  ← 修改：加版本一致性检查提示
README.md                   ← 修改：说明两种分析模式 + 版本 bump 规范
package.json                ← 版本升至 2.0.0
```

### 两条分析路径

```
/intelli:analyze
      ↓
  Phase 1: 收集平台信息 + 模式选择
      │
      ├─ 标准模式 ──→ Phase 2–5（现有三维度流程，不变）
      │
      └─ 链路模式 ──→ /intelli:flow-analyze
                            ↓
                      Phase A: AI 推导技术链路
                            ↓
                      用户确认 / 修正链路
                            ↓
                      Phase B: 逐段 API 验证
                      （每段：API端点 + 文档链接 + knowledge-base 参照）
                            ↓
                      Phase C: 链路可行性总结
                      （有条件/需开发 → 附三方资料）
                            ↓
                      生成链路报告（docs/platform-analysis/）
```

---

## 三、`intelli:analyze` 修改点

### Phase 1 新增模式选择

在收集业务背景（业务场景、目标、关注方向）后，追加：

```
你希望进行哪种分析？

→ 1. 标准能力评估
      输出三维度能力矩阵（工单AI回复 / Livechat对接 / 数据同步）
      适合：快速判断平台是否满足 Intelli 标准接入要求

→ 2. 业务链路验证
      描述你的业务目标，逐段验证技术链路可行性
      适合：有明确业务场景，需要知道端到端能否跑通
```

- 选 1：进入现有 Phase 2–5，不变
- 选 2：调用 `intelli:flow-analyze` skill，传入业务背景和平台信息

---

## 四、`intelli:flow-analyze` Skill 设计

### Phase A：技术链路推导

**输入：** 业务背景（来自 Phase 1）+ 平台列表

**AI 动作：**
1. 基于业务目标，将实现路径拆解为有序的 Step 序列
2. 每个 Step 标注：负责平台/系统、动作描述、前置依赖

**输出格式：**
```
技术链路: {业务目标名称}

Step N: {步骤名称}
  平台/系统: {Zoom CC / GHL / Zenoti / Intelli / shulex_gpt}
  动作: {具体操作描述}
  依赖: {前置条件或依赖项}
```

**用户确认：**
```
以上是 AI 推导的技术链路，是否符合你的预期？
→ 确认：进入逐段验证
→ 修正：说明哪些 Step 需要调整
```

等待用户确认或修正后，进入 Phase B。

---

### Phase B：逐段 API 验证

对每个 Step 执行以下分析：

**1. 确定操作类型：**
- 三方 API 调用 → 查文档，找具体端点
- 三方后台配置 → 找配置入口和说明文档
- 我方系统能力 → 查 knowledge-base，判断已有/待建

**2. 文档链接收集：**
- 优先使用 WebFetch 抓取官方文档
- 每个 API 端点 / 配置项都附对应文档 URL
- 若文档无法访问，标注"文档链接待确认"

**3. 可行性判断：**
- ✅ 可行：API 有明确文档，我方能力具备
- ⚠️ 有条件：需三方账户配置/权限，或有已知限制
- ⚠️ 需开发：三方 API 支持，我方能力待建
- ❌ 阻断：三方 API 不存在，或有根本性技术限制

**每 Step 输出格式：**
```
Step N 验证: {步骤名称}
─────────────────────────────────────
结论: {✅/⚠️/❌} {label}

API / 配置:
| 操作 | 类型 | 端点 / 入口 | 文档链接 |
|------|------|------------|---------|
| ...  | API / 后台配置 | ... | [...](URL) |

我方能力（knowledge-base）:
| 能力 | 状态 | 备注 |
|------|------|------|
| ...  | ✅/❌ | ... |

{若 ⚠️ 有条件:}
有条件说明: {具体限制描述 + 如何确认是否满足}
参考资料:
- [{资料名称}](URL)

{若 ⚠️ 需开发:}
需开发说明: {需新建/扩展的模块描述 + 预计工作量}
参考资料（供研发）:
- [{资料名称}](URL)

{若 ❌ 阻断:}
阻断原因: {具体说明为何无法实现}
```

---

### Phase C：链路可行性总结

所有 Step 验证完成后输出：

```
链路可行性总览: {业务目标名称}
═══════════════════════════════════════════════════════════════

| Step | 描述 | 结论 | 关键说明 |
|------|------|------|---------|
| Step 1 | ... | ✅/⚠️/❌ | ... |
...

整体结论:
- 完全可行的 Step: N 个
- 有条件/需开发的 Step: N 个（{列出 Step 编号}）
- 阻断的 Step: N 个（{列出 Step 编号}）

关键阻断点: {若无则写"无硬性阻断"}
主要前置条件: {列出所有"有条件"项的确认事项}
```

随后生成报告文件（见第六节）。

---

## 五、`intelli:update-kb` Skill 设计

### 触发方式
```
/intelli:update-kb
```
需要至少一个代码库已通过 `/add-dir` 加入上下文。

### 分析流程

**Step 1：检测可用代码库**
```
检测到以下代码库在当前上下文：
✅ shulex_intelli（路径: ...）
✅ shulex_gpt（路径: ...）
❌ 未检测到代码库 → 提示用户先 /add-dir
```

**Step 2：分析 shulex_intelli**
扫描以下内容：
- `ExternKeySourceEnum` 已注册的平台枚举值
- 已实现的 `TicketPlatformPlugin` 子类（已接入平台）
- `TicketOperations` 接口方法实现状态
- `ISyncService` 实现类（已支持同步类型）
- Livechat Engine 实现状态（WebSocket / Webhook / Voice）

**Step 3：分析 shulex_gpt**
扫描以下内容：
- 语音处理模块（ASR / TTS / 流式处理）
- NLU / 意图识别能力
- Tool Call / Function Call 支持
- 对话状态管理模块

**Step 4：生成 / 更新 knowledge-base 文件**
- 与现有文件对比，仅写入变更项
- 每个文件头部更新"最后更新时间"
- 新增能力标注 `NEW`，移除能力标注 `REMOVED`

**Step 5：提示后续操作**
```
knowledge-base 已更新：
- intelli-capabilities.md（N 项变更）
- shulex-gpt-capabilities.md（N 项变更）

请 bump package.json 版本号并 push，
团队成员执行 /plugin install intelli@intelli + /reload-plugins 后即可获取最新版本。
```

### knowledge-base 文件格式

**`intelli-capabilities.md`：**
```markdown
# Intelli 系统能力

> 最后更新: YYYY-MM-DD（by intelli:update-kb）

## TicketEngine V2 SPI
| 接口方法 | 状态 | 备注 |
|---------|------|------|
| parseWebhook() | ✅ | |
| getMessages() | ✅ | |
| sendReply() | ✅ | |
| applyTags() | ✅ | |
| getTags() | ✅ | |
| getSubject() | ✅ | |

## 已接入平台
| 平台 | 类型 | 状态 |
|------|------|------|
| Zendesk | Ticket | ✅ |
| Freshdesk | Ticket | ✅ |
| ...

## Livechat Engine
| 能力 | 状态 | 备注 |
|------|------|------|
| Webhook 模式 | ✅ | |
| WebSocket 模式 | ❌ | 未实现 |
| Voice Session Manager | ❌ | 未实现 |

## ISyncService
| 同步类型 | 状态 | 备注 |
|---------|------|------|
| 订单同步 | ✅ | |
| 商品同步 | ✅ | |
| 物流同步 | ⚠️ | 部分支持 |
```

**`shulex-gpt-capabilities.md`：**
```markdown
# shulex_gpt AI 能力

> 最后更新: YYYY-MM-DD（by intelli:update-kb）

## 语音处理
| 能力 | 状态 | 备注 |
|------|------|------|
| ASR（语音转文字） | ✅ | 支持 Whisper / 云端 ASR |
| TTS（文字转语音） | ✅ | 支持中文 |
| 实时流式 ASR | ⚠️ | 延迟 >500ms |

## 意图识别 / NLU
| 意图类型 | 状态 | 备注 |
|---------|------|------|
| 预约意图 | ✅ | |
| 取消/改期意图 | ✅ | |
| ...

## Tool Call
| 能力 | 状态 | 备注 |
|------|------|------|
| OpenAI tool call 格式 | ✅ | |
| 最大并发 tool 数 | 5 | |
```

---

## 六、报告格式（链路模式）

保存至：`docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}.md`

报告结构：

```markdown
# {业务目标} 链路可行性报告

> 分析日期: YYYY-MM-DD
> 涉及平台: {平台列表}
> 分析模式: 业务链路验证

## 一、链路总览（PM/交付用）

| Step | 描述 | 平台/系统 | 结论 | 说明 |
|------|------|----------|------|------|
| 1 | ... | ... | ✅/⚠️/❌ | ... |

**整体结论:** {可行 / 部分可行（N个条件）/ 存在阻断}
**主要前置条件:** {列表}

## 二、逐段详细分析（研发用）

### Step 1: {名称}
{完整 Step 验证输出，含 API 表格、文档链接、参考资料}

### Step 2: ...

## 三、实现 Checklist

{仅列出可行或有条件的 Step，每 Step 生成可执行的研发 checklist}
```

---

## 七、插件版本更新规范

### 规则
每次修改任何 `SKILL.md` 或 `knowledge-base/` 文件后，**必须** bump `package.json` 版本号：
- Patch（知识库更新、措辞修正）：`x.x.N`
- Minor（新增功能、流程调整）：`x.N.0`
- Major（架构重构）：`N.0.0`

### `install.sh` 改进
加入版本一致性检查：
```bash
CACHE_VERSION=$(cat ~/.claude/plugins/cache/intelli/intelli/*/package.json 2>/dev/null | grep version | head -1 | grep -o '[0-9.]*')
REPO_VERSION=$(cat package.json | grep version | grep -o '[0-9.]*')
if [ "$CACHE_VERSION" != "$REPO_VERSION" ]; then
  echo "⚠️  版本不一致：cache=$CACHE_VERSION, repo=$REPO_VERSION"
  echo "   请在 Claude Code 中执行：/plugin install intelli@intelli && /reload-plugins"
fi
```

---

## 八、版本规划

| 版本 | 内容 |
|------|------|
| v1.2.0 | 当前版本（Phase 1–5 重编号，cache 同步修复） |
| v2.0.0 | 本文档描述的完整重构 |
