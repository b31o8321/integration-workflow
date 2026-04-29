# E2E 验证指南 — 4 层端到端验收法

> 最后更新: 2026-04-29（首版，源自 ticket-v2 channel-auth-arch 验收实践）
>
> **适用场景**：需求合并到 master 之前的功能验收。**特别是涉及多服务、跨仓库、重构架构层**的需求。
> **核心思想**：把"纸面测试 case + 用户人工跑"升级为"4 层独立可重放 spec + 真人收尾"，让验收时间从 1 小时人工 → 5 分钟自动 + 真人确认。

---

## 0. 何时用本流程

| 场景 | 用本流程？ |
|------|-----------|
| 新平台接入 / 现有集成大改 | ✅ 必用 |
| 重构核心架构（如凭证体系、SPI 接口）| ✅ 必用 |
| 涉及跨服务（intelli ↔ Tars）| ✅ 必用 |
| 单文件 bugfix / 单测可覆盖 | ❌ 走单元测试即可 |
| 纯文档/前端样式调整 | ❌ 浏览器自查即可 |

---

## 1. 4 层验证策略

| 层 | 工具 | 验什么 | 文件命名约定 |
|----|------|------|------------|
| **L1 UI** | Playwright headed (含登录态) | 前端表单、接口契约、用户路径 | `*-auth.spec.ts` 或 `*.ui.spec.ts` |
| **L2 HTTP** | Playwright `request` API（无登录依赖） | 后端路由、签名、幂等、错误码 | `*.webhook.spec.ts` |
| **L3 SLS** | aliyunlog CLI + armsTrace 链路 | **跨服务不变量** —— 重构最该验这层 | `*-<invariant>.webhook.spec.ts` |
| **L4 真人** | watcher 模式（轮询 SLS 等真实 ID） | 黑盒结果（如 AI 回复是否送达） | `*-realuser.webhook.spec.ts` |

**层选择规则**：
- 纯后端改动 → 跳 L1
- 重构验收 → **L3 禁跳**（这层抓回归）
- AI 链路变动 → **L4 不可跳**
- 一切都需要 L2

---

## 2. Bootstrap：建一个 E2E 项目

> 该项目通常**不进主仓**，作为本机或团队私有的工程目录。每个开发者可以独立 bootstrap 自己的副本。

### 推荐位置

```
~/development/{your-org}/{repo}-e2e/      # 与主仓同级
```

### 初始化

```bash
mkdir -p ~/development/your-org/myproj-e2e && cd $_
npm init -y
npm install -D @playwright/test
npx playwright install chromium
```

### 最小骨架

```
myproj-e2e/
├── CLAUDE.md                # 该项目特有的 staging 坑、helper 模板
├── README.md                # 怎么跑
├── .gitignore               # auth/ artifacts/ playwright-report/ test-results/
├── package.json
├── playwright.config.ts     # 3 个 project: setup / chromium / webhook
└── tests/
    ├── auth.setup.ts        # 登录拿 storageState
    └── <feature>.spec.ts    # 业务测试
```

### `playwright.config.ts` 关键配置

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL ?? 'https://YOUR-STAGING-DOMAIN',
    headless: process.env.HEADED === '1' ? false : true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ignoreHTTPSErrors: true,
  },
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      testMatch: /.*\.ui\.spec\.ts$|.*-auth\.spec\.ts$/,
      use: { ...devices['Desktop Chrome'], storageState: 'auth/user.json' },
      dependencies: ['setup'],
    },
    {
      // HTTP-only — 跑得快，无浏览器无登录依赖
      name: 'webhook',
      testMatch: /.*\.webhook\.spec\.ts$/,
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

---

## 3. 跑前 Preflight（**每次跑前自查**）

### 必查工具

```bash
# Node + npm（Playwright 需要 Node 18+）
which node && node --version

# Playwright 浏览器已装
ls ~/Library/Caches/ms-playwright/ 2>/dev/null | grep -i chromium  # macOS
# Linux: ls ~/.cache/ms-playwright/

# SLS 查询工具（L3/L4 必需）
which aliyunlog && aliyunlog --version

# SLS 烟雾测试（确认 project/logstore 配置正确）
aliyunlog log get_log \
  --project="<your-sls-project>" \
  --logstore="<your-sls-logstore>" \
  --query='*' --from_time="-60s" --to_time="now" --size=1
```

### 必查环境变量

| 变量 | 用途 | 必需层 |
|------|------|------|
| `STAGING_EMAIL` / `STAGING_PASSWORD` | 登录态 | L1 |
| `BASE_URL` | 测试环境 baseURL（可选，默认值在 config） | 全部 |
| 平台凭证（如 `LINE_CHANNEL_ID`）| 第三方授权 | L1 / L2 |
| `*_WEBHOOK_URL` | webhook 入口 | L2 / L3 / L4 |

### 如果工具缺失

| 缺什么 | 怎么补 |
|------|------|
| Node | 装 nvm 或 brew，目标 v18+ |
| Playwright | `npm install -D @playwright/test && npx playwright install chromium` |
| aliyunlog | `pip install aliyun-log-cli`，然后 `aliyunlog configure` 配 AK/SK + region |
| SLS 权限 | 找 ops 或自己申请 RAM 角色 |

**preflight 不通过 → 不要硬跑，先补环境**。否则跑出来的 fail 都是工具问题不是业务问题。

---

## 4. 跨服务验证心法

### armsTrace 是跨服务串场器

`armsTrace`（不是 `trace`）是分布式追踪 ID，能把 intelli ↔ Tars ↔ 任何下游服务的日志串成一条链。32 位十六进制。

```ts
// 1. 触发 webhook 后等下游链路完成
await sleep(12_000);  // intelli → Tars → callback ≈ 10–15s

// 2. 从首个日志拿 armsTrace
const parseRows = querySls(`"[your-tag] Webhook parsed" and "channelId=${ID}"`, 120);
const armsTrace = parseRows[0].armsTrace;

// 3. 用 armsTrace 拉整条链
const trace = querySls(`"${armsTrace}"`, 600);
```

### 断言要宽松

SLS 的 `class` 字段是缩写名（如 `c.s.i.t.s.engine.TicketProcessingEngine`）。不要精确匹配。

```ts
// ❌ 错：精确字符串
expect(rows.some(r => r.class === 'com.shulex.intelli...TicketProcessingEngine')).toBe(true);

// ✅ 对：包尾 / 正则 / OR 多关键词
const allRest = rows.map(r => `${r.class}|${r.rest}`).join('\n');
expect(/processWebhook|inbox_create_request|Reply sent/.test(allRest)).toBe(true);
```

### 软 vs 硬断言分层

- **硬断言**（业务必过）：只查最关键节点。如 webhook 返回 200、`inbox_create_request` 出现
- **软断言**（fail 不阻断）：中间节点用 `console.log` 输出 + soft 比对，便于诊断
- 错把工具问题（断言太严）当成业务问题会浪费时间

---

## 5. 测试环境数据 — adopt-existing 模式

### 问题

测试环境后端常按业务键去重（如 `lineChannelId`、`shop_domain`），且**多数没有 DELETE 端点**。脚本试图"完全干净从零创建"必撞 409。

### 解法

```ts
async function findOrAdoptExistingChannel(page) {
  const list = await page.request.get('/api/{platform}/channels').then(r => r.json());
  const items = list?.data ?? list ?? [];
  for (const item of items) {
    const detail = await page.request.get(`/api/{platform}/channels/${item.id}`).then(r => r.json());
    if (String(detail.businessKey) !== EXPECTED_BUSINESS_KEY) continue;
    if (item.status !== 'enabled') {
      await page.request.post(`/api/{platform}/channels/${item.id}/enable`);
    }
    return detail;  // 复用现有
  }
  return null;  // 调用方走 UI 创建
}
```

### 收益

- 重复跑不报错
- 不依赖"开始前 tenant 是干净的"
- UI 创建流程 spec 写好就行，跑一次后续走 adopt 路径

---

## 6. 真人 watcher 模式

适用于**人在场才能触发**的场景（手机发 LINE 消息、客户拨入语音电话、Slack 点按钮）。

### 模式

1. 脚本启动 → 输出"请你执行 X"
2. 轮询 SLS（每 5s）等关键日志
3. 用真假 ID 区分（如真人 LINE userId = `U` + 32 hex；e2e 假 ID 用 `Ue2e-xxx`）
4. 抓到后用 `armsTrace` 拉整条链
5. 软断言关键节点 + 用户黑盒结果（如"手机收到回复了吗"）

### 骨架

```ts
const REAL_USER_RE = /U[0-9a-f]{32}/;
const TIMEOUT_MS = 5 * 60_000;

console.log('请用手机给测试 OA 发一条消息...');
let parseRow = null;
while (Date.now() - startedAt < TIMEOUT_MS) {
  const rows = querySls(`"[your-tag] Webhook parsed" and "channelId=${ID}"`, 120);
  parseRow = rows.find(r => REAL_USER_RE.test(r.rest));
  if (parseRow) break;
  process.stdout.write('.');
  await sleep(5_000);
}
expect(parseRow, '5 分钟内没在 SLS 看到真人消息').toBeTruthy();

await sleep(12_000);  // 等下游链路完成
const trace = querySls(`"${parseRow.armsTrace}"`, 600);
// 软断言关键节点
```

---

## 7. Spec 沉淀清单

每个验收项目跑通后留下：

| 文件 | 作用 |
|------|------|
| `<feature>-auth.spec.ts` | L1 授权 spec |
| `<feature>.webhook.spec.ts` | L2 路由 spec |
| `<feature>-<invariant>.webhook.spec.ts` | L3 跨服务不变量 spec |
| `<feature>-realuser.webhook.spec.ts` | L4 真人 watcher |
| `artifacts/<feature>-channel.json` | 阶段间共享数据（channelId、webhookUrl 等） |
| `CLAUDE.md` 增量 | 该 codebase 特有的 staging 坑（路由、登录、Antd 选择器约定等） |

下次重构 / 升级时直接重跑 spec，定位回归。

---

## 8. 通用 staging 坑（**新项目 bootstrap 时先收集**）

每个 staging 环境都有一组"非业务摩擦"，先收集到该项目的 `CLAUDE.md` 里，下次直接套用：

- 登录页选择器（placeholder vs id vs name）
- 路由 base path / 哈希路由 / 子应用路径
- Playwright `waitForLoadState` 选择（`networkidle` 在长连接应用永远不归零）
- Antd Form.Item id 约定（`#<name>` 还是 `<form>_<name>`）
- 后端 controller 路径是否含 gateway 前缀
- 状态枚举值（`enabled` / `deactivate` / `disabled` 各家不同）

**沉淀这些坑 = 节省下次开新需求 80% 的非业务摩擦时间**。

---

## 9. 与既有 superpowers 流程的关系

| superpowers skill | 在本流程中的角色 |
|-------------------|----------------|
| `verification-before-completion` | 仍然适用（提交前自查），本流程是它的"自动化执行"部分 |
| `test-driven-development` | 单元测试覆盖核心逻辑；本流程聚焦 E2E |
| `finishing-a-development-branch` | 本流程跑通 = 该 skill 的 verification 步骤完成 |

`intelli:e2e-verify` skill 编排本流程，自动检查 preflight + 引导 spec 编写。
