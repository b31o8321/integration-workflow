#!/bin/bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)/skills/intelli"

mkdir -p "$SKILLS_DIR"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: skills directory not found at $PLUGIN_DIR" >&2
  exit 1
fi

if [ -L "$SKILLS_DIR/intelli" ] || [ -e "$SKILLS_DIR/intelli" ]; then
  echo "Removing existing entry: $SKILLS_DIR/intelli"
  rm -rf "$SKILLS_DIR/intelli"
fi

ln -s "$PLUGIN_DIR" "$SKILLS_DIR/intelli"
echo "✓ Installed: ~/.claude/skills/intelli → $PLUGIN_DIR"
echo ""
echo "Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
