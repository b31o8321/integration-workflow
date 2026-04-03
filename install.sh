#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
PLUGIN_DIR="${REPO_DIR}/skills/intelli"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_JSON="${CLAUDE_DIR}/plugins/installed_plugins.json"
SETTINGS_JSON="${CLAUDE_DIR}/settings.json"
PLUGIN_KEY="intelli@local"
INSTALL_PATH="${REPO_DIR}"

# 1. Verify skills directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: skills directory not found at $PLUGIN_DIR" >&2
  exit 1
fi

# 2. Symlink skills
mkdir -p "$SKILLS_DIR"
if [ -L "$SKILLS_DIR/intelli" ] || [ -e "$SKILLS_DIR/intelli" ]; then
  echo "Removing existing entry: $SKILLS_DIR/intelli"
  rm -rf "$SKILLS_DIR/intelli"
fi
ln -s "$PLUGIN_DIR" "$SKILLS_DIR/intelli"
echo "✓ Skills symlinked: ~/.claude/skills/intelli → $PLUGIN_DIR"

# 3. Register plugin in installed_plugins.json
if [ -f "$PLUGINS_JSON" ]; then
  # Check if already registered
  if python3 -c "import json,sys; d=json.load(open('$PLUGINS_JSON')); sys.exit(0 if '$PLUGIN_KEY' in d.get('plugins',{}) else 1)" 2>/dev/null; then
    echo "✓ Plugin already registered in installed_plugins.json"
  else
    python3 - <<PYEOF
import json, datetime

path = "$PLUGINS_JSON"
with open(path) as f:
    data = json.load(f)

if "plugins" not in data:
    data["plugins"] = {}

data["plugins"]["$PLUGIN_KEY"] = [
    {
        "scope": "user",
        "installPath": "$INSTALL_PATH",
        "version": "1.0.0",
        "installedAt": datetime.datetime.utcnow().isoformat() + "Z",
        "lastUpdated": datetime.datetime.utcnow().isoformat() + "Z"
    }
]

with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("✓ Plugin registered in installed_plugins.json")
PYEOF
  fi
else
  echo "⚠️  installed_plugins.json not found at $PLUGINS_JSON — skipping plugin registration"
fi

# 4. Enable plugin in settings.json
if [ -f "$SETTINGS_JSON" ]; then
  if python3 -c "import json,sys; d=json.load(open('$SETTINGS_JSON')); sys.exit(0 if d.get('enabledPlugins',{}).get('$PLUGIN_KEY') else 1)" 2>/dev/null; then
    echo "✓ Plugin already enabled in settings.json"
  else
    python3 - <<PYEOF
import json

path = "$SETTINGS_JSON"
with open(path) as f:
    data = json.load(f)

if "enabledPlugins" not in data:
    data["enabledPlugins"] = {}

data["enabledPlugins"]["$PLUGIN_KEY"] = True

with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("✓ Plugin enabled in settings.json")
PYEOF
  fi
else
  echo "⚠️  settings.json not found at $SETTINGS_JSON — skipping settings update"
fi

# 5. Register SessionStart hook in settings.json
HOOK_CMD="bash ${REPO_DIR}/hooks/session-start"
if python3 -c "
import json, sys
d = json.load(open('$SETTINGS_JSON'))
hooks = d.get('hooks', {}).get('SessionStart', [])
for entry in hooks:
    for h in entry.get('hooks', []):
        if '$HOOK_CMD' in h.get('command', ''):
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  echo "✓ SessionStart hook already registered in settings.json"
else
  python3 - <<PYEOF
import json

path = "$SETTINGS_JSON"
with open(path) as f:
    data = json.load(f)

if "hooks" not in data:
    data["hooks"] = {}
if "SessionStart" not in data["hooks"]:
    data["hooks"]["SessionStart"] = []

data["hooks"]["SessionStart"].append({
    "hooks": [{"command": "$HOOK_CMD", "type": "command"}]
})

with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("✓ SessionStart hook registered in settings.json")
PYEOF
fi

# 6. Write skill listing to ~/.claude/CLAUDE.md (always loaded in every session)
GLOBAL_CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
MARKER="## Intelli Platform Analysis Skills"

if [ -f "$GLOBAL_CLAUDE_MD" ] && grep -q "$MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  echo "✓ ~/.claude/CLAUDE.md already contains intelli skill listing"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<MDEOF

## Intelli Platform Analysis Skills

You have the following intelli skills available via the Skill tool:

- **intelli:analyze** — Full platform analysis flow with checkpoints. Orchestrates check-api → map-arch → report. Use for any platform feasibility evaluation. Optionally hands off to superpowers:brainstorming.
- **intelli:check-api** — Phase 1: analyze raw API capabilities across Ticket AI Reply, Livechat, and Data Sync dimensions. Outputs a capability matrix.
- **intelli:map-arch** — Phase 2: map platform capabilities to Shulex Intelli architecture (TicketEngine V2 SPI, Livechat engine, ISyncService). Identifies gaps.
- **intelli:report** — Phase 3: generate two-tier feasibility report (PM summary + dev checklist). Saves to docs/platform-analysis/.

When the user uses /intelli:analyze, /intelli:check-api, /intelli:map-arch, or /intelli:report, or asks to evaluate a platform for Intelli compatibility, invoke the corresponding skill via the Skill tool.
MDEOF
  echo "✓ Intelli skill listing added to ~/.claude/CLAUDE.md"
fi

echo ""
echo "✓ Installation complete. Restart Claude Code to activate."
echo ""
echo "Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
