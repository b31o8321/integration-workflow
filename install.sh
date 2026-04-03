#!/bin/bash
set -e

SKILLS_DIR="$HOME/.claude/skills"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)/skills/intelli"

mkdir -p "$SKILLS_DIR"

if [ -L "$SKILLS_DIR/intelli" ]; then
  echo "Removing existing symlink: $SKILLS_DIR/intelli"
  rm "$SKILLS_DIR/intelli"
fi

ln -s "$PLUGIN_DIR" "$SKILLS_DIR/intelli"
echo "✓ Installed: ~/.claude/skills/intelli → $PLUGIN_DIR"
echo ""
echo "Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
