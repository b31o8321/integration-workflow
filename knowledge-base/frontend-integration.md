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
- 独立页面（新）：`Channel/mod/ShopifyAuth/`、`Channel/mod/LineAuth/`、`Channel/mod/LiveAgentAuth/`
