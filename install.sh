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
echo "Restart Claude Code to activate. Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
