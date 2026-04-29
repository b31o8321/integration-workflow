# SDK 发布指南

> Tars 依赖 `shulex-intelli-sdk` 的 RELEASE/SNAPSHOT 版本。SDK 改动后必须先发布，Tars CI 才能编译通过。

## 背景

`shulex-intelli-sdk` 的开发版本是 SNAPSHOT（如 `1.3.46-SNAPSHOT`），Tars 的 pom.xml 引用的是该版本。如果 SDK 新增了枚举值或接口但未发布到 Nexus，Tars CI 会因找不到该类而编译失败。

## 发布步骤

每当在 `shulex-intelli-sdk` 里新增枚举值或接口，且 Tars 需要引用时：

**Step 1：本地发布 SDK SNAPSHOT 到 Nexus**

```bash
JAVA_HOME=/path/to/jdk8 \
  mvn deploy -pl shulex-intelli-sdk -am -DskipTests=true \
  -f ~/development/vibe-coding/shulex-intelli/pom.xml
```

**Step 2：确认 Tars pom.xml 引用的版本与 SDK 当前版本一致**

```xml
<!-- tars-service/pom.xml -->
<artifactId>shulex-intelli-sdk</artifactId>
<version>1.3.46-SNAPSHOT</version>  <!-- 改为当前开发版本 -->
```

**Step 3：在 Tars feature 分支提交后，合并到 staging 分支推送触发 CI**

## 常见症状

- Tars CI 报 `cannot find symbol: ExternKeySourceEnum.XXXX`
- Tars CI 报 `package com.shulex.xxx does not exist`
- Intelli CI 报 `cannot find symbol: VoiceAttachment / setPhoneType / setVoiceDuration` 之类（来自 `tars-client`）

→ 原因：SDK / Client 改了但**未 deploy**，或下游 pom.xml 版本号未更新。**本地 mvn install 看不到 Nexus 上的旧 JAR**——本地能跑 CI 不能跑就是这个症状。

## 跨仓变更对照表（开发前必填）

涉及多仓库的需求，开发**前**先填一份 checklist：

| 仓库 | 改什么 | 版本号是否递增 + deploy | 部署顺序 |
|------|------|------|------|
| `shulex-intelli-sdk` | 新增枚举/字段 | **必须**：版本号 +1 + `mvn deploy` 到 Nexus | 第 1 |
| `tars-client` | 新增方法/字段（如 `InboxCreateRequest.VoiceAttachment` 内部类）| 同上 | 第 1 |
| 服务端（intelli/tars）| 引用新字段 | pom 升版本号 | 第 2 |
| 前端 | 调新接口 | - | 第 3 |

**反模式**（不要做）：
- 改 SDK 源码不递增版本号——CI 拉的还是 Nexus 上的旧 JAR
- 同一个 SNAPSHOT 重新 deploy 覆盖——破坏构建可重现性
- 多仓 PR 同时 merge 不分先后——下游编译时上游 JAR 还没出
