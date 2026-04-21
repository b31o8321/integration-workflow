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

→ 原因：SDK 改了但未 deploy，或 Tars pom.xml 版本号未更新。
