---
name: retrospective
description: Post-development retrospective. Two modes — integration project (updates plugin knowledge base and skill files) or general feature work (updates CLAUDE.md and project docs with architecture conventions and lessons learned). Run after finishing any significant development branch.
version: 1.2.0
---

# intelli:retrospective — Post-Development Retrospective

## Purpose

开发分支完成后，进行结构化复盘。根据开发内容自动选择复盘模式：

**模式 A：集成项目复盘**（新接入平台 / 现有集成改造）
1. 更新 `knowledge-base/intelli-capabilities.md`（新平台、新发现）
2. 修正集成分析 Skill 中的知识错误或流程空缺
3. 提炼并确认本次发现的架构约定
4. 更新 `shulex-intelli/CLAUDE.md`（如有新的架构规则）
5. Bump 插件版本（如有 Skill 或知识库变更）

**模式 B：通用功能复盘**（非集成项目的新功能 / 架构改造）
1. 总结本次发现的架构约定、坑点、决策
2. 更新 `shulex-intelli/CLAUDE.md` 或 `docs/CLAUDE_ONBOARDING.md`
3. 如影响集成分析（如新的 SPI 方法、新的引擎能力），同步更新知识库

## 触发时机

- **`superpowers:finishing-a-development-branch` 执行完成之后**，由 Claude 主动询问
- 用户手动执行 `/intelli:retrospective`

## Input & Mode Selection

优先从当前会话上下文判断；无法判断时询问：

```
本次开发是集成项目（新平台接入 / 现有集成改造）还是其他功能？

→ A. 集成项目
→ B. 其他功能
```

---

## Mode A: 集成项目复盘

需要以下信息（从上下文读取，或询问）：

```
1. 平台名称: {e.g. LiveAgent}
2. 实现的功能: {Ticket AI 回复 / Livechat / 数据同步 / 前端接入页，可多选}
3. 开发过程中遇到的偏差或纠正点: {描述；若无则填"无"}
```

读取 `knowledge-base/intelli-capabilities.md`，逐项核对：

**1.1 已接入平台列表**
- 新平台是否已加入对应凭证模式分区（ChannelAuth / ExternKey）？
- 平台类型（Ticket / Livechat / 数据同步）是否正确？

**1.2 已实现 TicketPlatformPlugin 平台表**
- 新平台是否已列入？凭证模式、参考实现是否填写？

**1.3 SPI 方法状态**
- 本次开发中是否发现任何方法行为与文档描述不符？

**1.4 新凭证模式或 Adapter 模式**
- 若引入了新的代码模式（如 `toExternKey()` adapter），是否需要记录为约定？

若有变更 → 执行更新，刷新顶部"最后更新"日期
若无变更 → 输出 `intelli-capabilities.md 无需更新`

---

### Step 2: Skill 质量检查

对照本次开发过程，逐一评估以下 Skill 文件是否存在误导性或缺失内容：

| 文件 | 检查重点 |
|------|---------|
| `skills/map-arch/SKILL.md` | 架构映射表 SPI 方法说明是否准确；枚举注册是否指向正确（ChannelTypeEnum not ExternKeySourceEnum）|
| `skills/check-api/SKILL.md` | 能力矩阵维度是否覆盖了本次新情况 |
| `skills/report/SKILL.md` | spec.md / dev.md Checklist 是否需要补充；E2E 验收要求是否完整 |
| `skills/analyze/SKILL.md` | 流程卡点是否需要说明；brainstorming 传入的 context 是否足够 |
| `skills/update-kb/SKILL.md` | 知识库扫描逻辑是否需要新增（如 ChannelTypeEnum 扫描）|

**只在发现实际问题时更新，不做预防性修改。**

---

### Step 3: 架构约定提炼

若本次开发发现了新的架构约定，输出总结：

```
本次提炼的架构约定：
- {约定描述}: {一句话说明，如 "新平台统一用 ChannelAuth，覆盖 resolveCredential() + resolveCredentialByKey()，参考 LineTicketPlugin"}
```

检查每条约定是否已覆盖：

| 约定 | intelli-capabilities.md | map-arch | report spec.md checklist | shulex-intelli CLAUDE.md |
|------|:---:|:---:|:---:|:---:|
| {约定} | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |

对任何 ❌ 项执行补充更新。

若无新约定 → 输出 `无新架构约定`

---

### Step 3.5: E2E Spec 沉淀检查

询问 / 自检：

```
本次开发是否有 E2E spec 沉淀？（4 层验证法 — UI / HTTP / SLS / 真人）

→ 已沉淀: 列出 spec 文件路径
→ 部分沉淀: 哪些层做了，哪些没做
→ 未沉淀: 是否需要补？跑 /intelli:e2e-verify 引导
```

判断标准（建议沉淀）：

- [ ] 涉及跨服务调用（intelli ↔ Tars 等）→ **L3 SLS 不可跳**
- [ ] 改了授权 / 凭证模式 → L1 + L2 必须有 spec
- [ ] 改了 webhook 入口 / 路由 → L2 必须有 spec
- [ ] AI 回复链路相关 → **L4 真人 watcher 不可跳**

如果未沉淀，提示：

```
⚠️ 本次开发未留 E2E spec。下次回归只能再跑人工测试。
   建议跑 `/intelli:e2e-verify <feature>` 引导沉淀，~30 分钟生成 spec 集，后续重跑 5 分钟。
   是否现在跑？
```

如已沉淀，提示同步以下信息到 plugin（如适用）：

- 新发现的 staging 坑 → 项目本地 `CLAUDE.md`（不进 plugin）
- 新发现的跨项目通用经验 → `knowledge-base/e2e-verification-guide.md`（进 plugin，本步骤补一段）
- 新发现的业务约定 → `intelli-capabilities.md` Step 1 已覆盖

---

### Step 4: 版本更新

若 Step 1–3.5 修改了任何文件：

```bash
# 仅知识库更新 → patch
# Skill 流程或模板变更 → minor
```

更新顺序：
1. `package.json` — bump 版本号
2. `.claude-plugin/plugin.json` — 同步版本号
3. `.claude-plugin/marketplace.json` — 同步版本号
4. `CHANGELOG.md` — 添加版本条目，列出变更项
5. `README.md` — 若有新 Skill 或重要变更，更新对应说明

Commit 并 push：
```bash
git add -A
git commit -m "chore: post-integration retrospective — {platform}"
git push
```

若无任何修改 → 输出 `插件无需更新`

---

## Mode B: 通用功能复盘

需要以下信息（从上下文读取，或询问）：

```
1. 本次开发的功能简述: {e.g. 重构 ChannelAuth 凭证模式}
2. 开发中遇到的坑点或决策点: {描述；若无则填"无"}
3. 是否影响集成分析流程或系统能力描述？{是/否}
```

### Step B1: 架构约定与坑点总结

整理本次开发中发现的以下类别信息：

- **架构决策**：选了某方案而非另一方案，为什么？
- **坑点 / 陷阱**：踩过的坑，避免未来重踏
- **新的代码约定**：e.g. 某类实现必须用某种方式
- **文档与代码不一致**：发现的错误或过时描述

### Step B2: 更新 shulex-intelli 项目文档

根据 B1 整理的内容，更新以下文件（按需）：

| 文件 | 适用内容 |
|------|---------|
| `CLAUDE.md` | 架构决策、代码约定、必须注意的规则 |
| `docs/CLAUDE_ONBOARDING.md` | 新人上手相关、模块说明、运行方式 |
| 相关模块 README | 若涉及特定模块的使用方式变化 |

**只更新有实际内容写入的地方，不增加空洞的章节。**

### Step B3: 如影响集成分析，同步更新插件

若本次开发新增了 SPI 方法、新的引擎能力、或修改了已有能力的行为：
- 更新 `knowledge-base/intelli-capabilities.md`
- Bump 插件版本（patch）
- Commit 并 push

若无影响 → 跳过，无需 bump 插件版本

### Step B4: E2E Spec 沉淀检查

同 Mode A Step 3.5 — 检查本次开发是否有 4 层 E2E spec 沉淀。判断标准 + 处理方式参见 Mode A 同名步骤。**Mode B 通用功能也鼓励沉淀**，特别是涉及多服务、跨仓、重构架构的改动。

---

## Output Format

复盘完成后输出：

```
复盘完成：{功能/平台描述}

模式: {A 集成项目 / B 通用功能}
知识库更新: {更新了 X 项 / 无需更新}
Skill 更新: {更新了 X 个文件 / 无需更新}（仅 Mode A）
文档更新:   {更新了 X 个文件 / 无需更新}（仅 Mode B）
架构约定:   {提炼了 X 条 / 无新约定}
插件版本:   {已 bump 至 X.X.X / 无变化}

{若有重要发现或后续建议，此处附一段话}
```
