# 前端集成约定

> shulex-smart-service 前端项目的集成页面架构与新平台接入规范。

## 技术栈

- **框架**: Umi 4.x (React 18.x) + TypeScript
- **状态管理**: Recoil（integration 模块）+ MobX（全局）
- **UI**: Ant Design 5.x + Shulex Design

## Integration 页面双流程架构

| 流程 | 适用 | 入口 | 授权组件位置 |
|------|------|------|------------|
| 旧流程（Drawer） | SLG 用户 | `integration/index.tsx` | `Drawers/{Platform}/` |
| 新流程（独立页面） | PLG + 新平台 | `Channel/index.tsx?type=Platform` | `Channel/mod/{Platform}Auth/` |

**新平台统一使用新流程**，脚手架组件：`AuthPageScaffold`、`AuthBanner`、`AuthSection`、`AuthOption`、`StepInfo`。

## 新增平台必须修改的 4 个地方

1. **`src/services/integration.ts`** — `Channel` 类型新增枚举值 + 添加 API 函数
2. **`src/pages/integration/Channel/index.tsx`** — switch case 新增平台路由（`?type=Platform`）
3. **`src/pages/integration/index.tsx`** — `getIntegrationList()` 新增平台卡片
4. **`src/pages/integration/Channel/mod/{Platform}Auth/`** — 实现授权页面

## i18n 规范（强制）

所有展示给用户的文案必须通过 i18n，**禁止硬编码中文或英文字符串**。

产品支持 7 种语言：`cn / en / pt / de / fr / es / jp`

- **文件位置**：`src/i18n/{cn,en,pt,de,fr,es,jp}/integrate.ts`
- **调用方式**：`import i18n from '@/i18n'`，使用 `i18n('integrate.键名')`
- **Key 命名**：`integrate.{Platform}_{描述}`，例：`integrate.LiveAgent_connection_title`
- 新增平台时，**7 个语言文件全部添加**对应 key；非英语语言可先用英文占位
- 检查命令：`grep -n "content: '" src/pages/integration/index.tsx`

## 参考实现

- Drawer 方式（旧）：`Drawers/Zendesk/index.tsx`
- 独立页面（新）：`Channel/mod/ShopifyAuth/`、`Channel/mod/LineAuth/`、`Channel/mod/LiveAgentAuth/`、`Channel/mod/CustomTicketAuth/`

## 错误处理分层契约

**网络拦截器已统一弹错误 toast**。业务代码再 `try/catch + message.error` 会弹两次。

| 层 | 职责 | 不该做 |
|----|------|------|
| 网络拦截器 | 统一弹错误 toast / 401 跳登录 | 业务判断 |
| 业务 hook/service | 业务流程控制（重试/降级/状态切换）| 错误 UI 展示 |
| 组件层 | 渲染 + 用户操作 | 直接 catch 网络错误并弹 toast |

**何时合法用 try/catch**：表单 `validateFields` 控制流、`finally` 重置 loading、错误时切到降级路径（不展示给用户）。

**何时不用**：单纯调 API、catch 里只是 `message.error('xxx')` → 删掉。

## 样式管理边界

| 用法 | 适用场景 |
|------|------|
| CSS Module（`.module.less`）| 默认选择，组件级别样式 |
| 全局样式 | 主题、reset、动画 |
| 行内 `style={...}` | **仅限**运行时计算的动态值（按 prop 算 width 等）|

新组件不允许大量使用 `style={{...}}`，应抽到 `*.module.less` 用 className。

## 重命名的穿透性

任何重命名必须穿透所有维度才算完成。**漏一层就是债**：

- 代码：class、function、变量、type
- 标识：enum 值、API URL、字符串字面量（含 switch case 的 string）
- 工程：文件夹名、文件名
- 资源：i18n key、less 类名
- 文档：注释、README

**重命名时同步修改的文件**（除"新增平台 4 处"外还要看）：

5. `src/pages/integration/ChannelList/columns/Settings/index.tsx` — `xxxSettingsColumn` 命名
6. `src/pages/integration/ChannelList/components/PlatformChannelList.tsx` — `PlatformType` 联合类型字面量

## Push 前自检

```bash
git diff <feature-base> --stat       # 自我 diff，逐个 hunk 自问"属于本需求吗？"
grep -rn "OldName" src --include="*.ts" --include="*.tsx"   # 重命名残留
yarn tsc --noEmit 2>&1 | grep "error TS"                     # 类型错误
```
