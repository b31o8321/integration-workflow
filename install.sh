#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

# Remove existing entry (symlink or directory)
if [ -L "$SKILLS_DIR/intelli" ] || [ -e "$SKILLS_DIR/intelli" ]; then
  echo "Removing existing entry: $SKILLS_DIR/intelli"
  rm -rf "$SKILLS_DIR/intelli"
fi

# Link repo's skills/ directory as the intelli namespace
ln -s "${REPO_DIR}/skills" "$SKILLS_DIR/intelli"
echo "✓ Installed: ~/.claude/skills/intelli → ${REPO_DIR}/skills"
echo ""
echo "可用 skills:"
echo "  /intelli:analyze     — 平台分析入口（标准模式 + 链路模式）"
echo "  /intelli:flow-analyze — 业务链路验证（独立使用）"
echo "  /intelli:check-api   — 独立 API 能力检查"
echo "  /intelli:map-arch    — 独立架构映射"
echo "  /intelli:report      — 独立报告生成"
echo "  /intelli:update-kb   — 更新系统能力知识库（需 /add-dir 代码库）"
echo ""
echo "⚠️  版本管理提醒："
echo "   修改任何 SKILL.md 或 knowledge-base/ 文件后，必须 bump package.json 版本号。"
echo "   Patch（知识库/措辞）: x.x.N | Minor（新功能）: x.N.0 | Major（架构）: N.0.0"
echo ""

# 版本一致性检查
CACHE_PKG=$(ls "$HOME/.claude/plugins/cache/intelli/intelli/"*/package.json 2>/dev/null | head -1)
if [ -n "$CACHE_PKG" ]; then
  CACHE_VERSION=$(grep '"version"' "$CACHE_PKG" | grep -o '[0-9][0-9.]*' | head -1)
  REPO_VERSION=$(grep '"version"' "${REPO_DIR}/package.json" | grep -o '[0-9][0-9.]*' | head -1)
  if [ "$CACHE_VERSION" != "$REPO_VERSION" ]; then
    echo "⚠️  版本不一致：plugin cache=$CACHE_VERSION，repo=$REPO_VERSION"
    echo "   请在 Claude Code 中执行：/plugin install intelli@intelli && /reload-plugins"
  else
    echo "✓ 版本一致：$REPO_VERSION"
  fi
fi
