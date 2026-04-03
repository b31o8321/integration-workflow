#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_JSON="${CLAUDE_DIR}/plugins/installed_plugins.json"
SETTINGS_JSON="${CLAUDE_DIR}/settings.json"
PLUGIN_KEY="intelli@local"

# Remove legacy symlink if present
if [ -L "${CLAUDE_DIR}/skills/intelli" ]; then
  echo "Removing legacy symlink: ~/.claude/skills/intelli"
  rm "${CLAUDE_DIR}/skills/intelli"
fi

# Verify Claude Code is installed
if [ ! -f "$PLUGINS_JSON" ]; then
  echo "Error: Claude Code plugins registry not found at $PLUGINS_JSON" >&2
  echo "Make sure Claude Code is installed." >&2
  exit 1
fi

# Register in installed_plugins.json
if python3 -c "import json,sys; d=json.load(open('$PLUGINS_JSON')); sys.exit(0 if '$PLUGIN_KEY' in d.get('plugins',{}) else 1)" 2>/dev/null; then
  echo "✓ Plugin already registered: $PLUGIN_KEY"
else
  python3 - <<PYEOF
import json
from datetime import datetime, timezone

path = "$PLUGINS_JSON"
with open(path) as f:
    data = json.load(f)

data.setdefault("plugins", {})["$PLUGIN_KEY"] = [{
    "scope": "user",
    "installPath": "$REPO_DIR",
    "version": "1.0.0",
    "installedAt": datetime.now(timezone.utc).isoformat(),
    "lastUpdated": datetime.now(timezone.utc).isoformat()
}]

with open(path, "w") as f:
    json.dump(data, f, indent=4)

print("✓ Registered: $PLUGIN_KEY")
PYEOF
fi

# Enable in settings.json
if [ -f "$SETTINGS_JSON" ]; then
  if python3 -c "import json,sys; d=json.load(open('$SETTINGS_JSON')); sys.exit(0 if d.get('enabledPlugins',{}).get('$PLUGIN_KEY') else 1)" 2>/dev/null; then
    echo "✓ Plugin already enabled in settings.json"
  else
    python3 - <<PYEOF
import json

path = "$SETTINGS_JSON"
with open(path) as f:
    data = json.load(f)

data.setdefault("enabledPlugins", {})["$PLUGIN_KEY"] = True

with open(path, "w") as f:
    json.dump(data, f, indent=4)

print("✓ Enabled in settings.json")
PYEOF
  fi
fi

echo ""
echo "✓ Installation complete. Restart Claude Code to activate."
echo ""
echo "Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
