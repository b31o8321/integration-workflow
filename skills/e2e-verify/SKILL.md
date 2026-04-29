---
name: e2e-verify
description: Bootstrap or run a 4-layer end-to-end verification (UI / HTTP / SLS / real-user) for a feature or refactor against the staging environment. Performs preflight checks, helps the user create an E2E project if missing, and generates layered Playwright specs that produce reusable regression coverage. Use when the user says "帮我验证 X 需求" / "做 E2E 测试" / "验收 channel-auth-arch" — anything beyond paper test cases.
version: 1.0.0
---

# intelli:e2e-verify — 4 层 E2E 验收编排

## Purpose

把"纸面测试 case + 用户人工跑"升级为"可重放的 4 层 spec + 真人收尾"。

**编排逻辑**：preflight 检查 → 确认 / 引导 bootstrap E2E 项目 → 按需生成各层 spec → 跑 + 报告 → 沉淀复用。

依赖知识库文档：`knowledge-base/e2e-verification-guide.md`（先读它了解 4 层模型）。

---

## 触发时机

用户说类似的话时主动调用：

- "帮我验证 X 需求 / X 重构"
- "做端到端测试"
- "验收 / 回归 / E2E"
- 描述了一个跨服务或跨仓库需求并问"测试方案"

也响应直接 `/intelli:e2e-verify <feature>` 调用。

---

## Step 0：判断是否走本流程

询问用户（或从上下文判断）：

```
本次验证是哪类？

1. 单文件 bugfix / 单测可覆盖   → 走 superpowers:test-driven-development（不在本流程）
2. 纯前端样式 / 文档调整         → 浏览器自查即可（不在本流程）
3. 涉及多服务 / 跨仓 / 重构架构 / 集成接入   → ✅ 本流程
```

只有 (3) 进入下面步骤。

---

## Step 1：Preflight 检查（**每次必跑**）

依次检查并报告每一项的状态。**任一关键项缺失先补齐再继续**。

### 1.1 工具

```bash
# Node 18+
which node && node --version
# 期望：v18.x 或 v20.x

# Playwright runner 可用
npx --no-install playwright --version 2>&1 || echo "not installed"
# 期望：Version X.Y.Z；如 not installed，问是否在目标项目下 npm install -D @playwright/test

# Chromium 已装
ls ~/Library/Caches/ms-playwright/ 2>/dev/null | grep -i chromium || \
  ls ~/.cache/ms-playwright/ 2>/dev/null | grep -i chromium
# 期望：chromium-XXXX 目录；缺 → npx playwright install chromium

# SLS 查询工具（L3/L4 必需）
which aliyunlog && aliyunlog --version
# 期望：log-cli-v-X.X.X；缺 → pip install aliyun-log-cli && aliyunlog configure
```

### 1.2 SLS 烟雾测试（确认 project/logstore 配置 + 网络通）

向用户确认 SLS project/logstore 名称（首次使用），然后：

```bash
aliyunlog log get_log \
  --project="<sls-project>" \
  --logstore="<sls-logstore>" \
  --query='*' --from_time="-60s" --to_time="now" --size=1
```

期望：返回非空 JSON 数组，含 `armsTrace`、`service`、`class`、`rest` 字段。

如果 401 / 403 → 提示 `aliyunlog configure` 配 AK/SK。

### 1.3 必需环境变量

| 变量 | 必需层 | 缺失处理 |
|------|------|------|
| `STAGING_EMAIL` / `STAGING_PASSWORD` | L1 | 询问用户 |
| `BASE_URL` | 全部（可选） | 用 default，告知用户 |
| 平台 creds（如 `LINE_CHANNEL_ID`）| L1 / L2 | 询问用户 |
| `*_WEBHOOK_URL` | L2 / L3 / L4 | L1 跑完后从产物 / staging UI 拷 |

### 1.4 测试环境联通

```bash
curl -s -o /dev/null -w "%{http_code}" "${BASE_URL:-https://your-staging-domain}/"
# 期望：200 / 301 / 302
```

### Preflight 输出格式

```
preflight 检查
─────────────────────────
✓ Node 20.20.2
✓ Playwright runner 1.59.1
✓ Chromium installed
✓ aliyunlog log-cli-v-0.2.10
✓ SLS smoke test passed (project=xxx, logstore=yyy)
✓ STAGING_EMAIL set
✓ STAGING_PASSWORD set
✗ LINE_ACCESS_TOKEN missing       ← 询问用户
─────────────────────────
全部通过 / 缺 N 项 → 继续 / 阻塞
```

---

## Step 2：定位 / Bootstrap E2E 项目

询问用户：

```
本次验证用哪个 E2E 项目？

1. 已有项目 → 提供路径（建议同级于主仓，如 ~/development/your-org/myproj-e2e）
2. 新建项目 → 我引导 bootstrap
```

### 2a. 已有项目

```bash
cd <path>
# 检查骨架
ls playwright.config.ts tests/ artifacts/ 2>/dev/null
```

如果缺 `playwright.config.ts` 或 `tests/`：提示用户该项目可能不是 Playwright 项目。

### 2b. 新建项目

引导：

```bash
mkdir -p ~/development/your-org/<repo>-e2e && cd $_
npm init -y
npm install -D @playwright/test
npx playwright install chromium
```

然后写入：
- `playwright.config.ts`（3 个 project: setup / chromium / webhook，参考 `e2e-verification-guide.md` Step 2）
- `tests/auth.setup.ts`（登录拿 storageState）
- `.gitignore`（auth/ artifacts/ playwright-report/ test-results/）
- `CLAUDE.md`（项目说明 + staging 坑收集位）
- `README.md`（运行说明）

参考实现：`knowledge-base/e2e-verification-guide.md` 第 2 章。

> ⚠️ 默认**不推 Git 远程**。E2E 项目作为本机/团队私有工程目录，每个开发者独立 bootstrap。流程通过本插件共享，不通过共享仓库。

---

## Step 3：选择并生成 spec 层

向用户确认本次需求适配哪些层：

```
本次需求要覆盖哪些层？（按需多选）

L1 UI       — 前端表单 + 接口契约（纯后端可跳）
L2 HTTP     — 后端路由 + 幂等（不可跳）
L3 SLS      — 跨服务不变量，重构验收禁跳
L4 真人     — 黑盒结果（如 AI 回复送达），AI 链路不可跳
```

**默认推荐**：
- 接平台 / 改授权：L1 + L2 + L3
- 重构跨服务架构：L2 + L3 + L4
- 纯 webhook 路径改动：L2 + L3
- AI 回复链路：L2 + L3 + L4

每层生成对应 spec 文件（命名约定见 guide）。

### Spec 模板要点（生成时遵守）

| 项 | 约定 |
|----|------|
| 选择器优先级 | `getByRole` > `getByPlaceholder` > Form.Item id (`#<name>`) > `hasText` > CSS |
| 不要用 `waitForLoadState('networkidle')` | 长连接应用永远不归零，必超时；用 `domcontentloaded` |
| baseURL | 走 `process.env.BASE_URL`，不硬编码 |
| 凭证 | 走 env，不硬编码 |
| 业务键去重场景 | 用 adopt-existing 模式（list → 匹配 → enable + 复用） |
| SLS 等待时间 | 跨服务 callback ≈ 12s，等够再查 |
| 跨服务节点断言 | 宽松正则 + OR 多关键词，不精确字符串匹配 |
| 真人 watcher | 用 ID 形态区分真人 vs e2e（如 LINE 真人 `U[0-9a-f]{32}`） |
| Artifact | 关键产物（channelId / webhookUrl）写 `artifacts/<feature>-channel.json` 跨阶段共享 |

参考已有实现示例：`knowledge-base/e2e-verification-guide.md` 第 4–6 章。

---

## Step 4：跑 + 报告

```bash
# 全套
HEADED=1 npx playwright test

# 仅某层
npx playwright test --project=webhook       # L2/L3/L4
npx playwright test tests/<spec-name>       # 单 spec
```

### 报告格式

```
E2E 验收结果 — <feature>
═══════════════════════════════════════════════════════
Spec 数:   <N>
通过:      <N>
失败:      <N>

[L1 UI]
✓ <spec name>      ()
✗ <spec name>      Error: <msg>

[L2 HTTP]
✓ ...

[L3 SLS] — 关键不变量
✓ aiSetting{aiOpened, botId, token} 完整
✓ channel == "line", channelId 正确
✓ hasPlatform(...) routes V2

[L4 真人] — 用户黑盒结果
✓ 链路日志全节点命中
? 手机收到 AI 回复？（用户确认）

artifact: artifacts/<feature>-channel.json
═══════════════════════════════════════════════════════
```

### Fail 排查优先级

1. **先怀疑选择器**（class 缩写、断言太严）—— 看 SLS 实际证据是否在
2. **再怀疑环境**（preflight 漏了什么）
3. **最后怀疑业务**（确实回归）

---

## Step 5：沉淀

跑通后**必须沉淀**：

1. spec 文件留在 E2E 项目，下次直接重跑
2. 该 codebase 特有的新坑写到 E2E 项目的 `CLAUDE.md`
3. 跨项目通用经验更新到本插件 `knowledge-base/e2e-verification-guide.md`
4. 业务约定（如新平台必须实现的 SPI 行为）→ `superpowers:retrospective` 流程

### 输出 sedimentation summary

```
本次沉淀
─────────────────────────
新增 spec:        <N> 个
更新 CLAUDE.md:   是 / 否（项目内）
更新 plugin:      是 / 否（建议跑 intelli:retrospective）
新发现的 staging 坑: <list>
─────────────────────────
```

---

## Standalone vs Orchestrated

- **Standalone** (`/intelli:e2e-verify <feature>`)：完整跑 Step 0–5
- **Orchestrated**（从 `superpowers:finishing-a-development-branch` 调用）：跑 Step 1–4，最后建议 `intelli:retrospective`
