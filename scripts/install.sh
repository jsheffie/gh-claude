#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="gh-claude"
PLUGIN_VERSION="1.1.0"
MARKETPLACE_KEY="gh-claude"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache/$MARKETPLACE_KEY/$PLUGIN_NAME/$PLUGIN_VERSION"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"

main() {
  echo "Installing $PLUGIN_NAME v$PLUGIN_VERSION..."

  mkdir -p "$CACHE_DIR"

  # Copy plugin contents (exclude .git and Formula)
  rsync -a \
    --exclude='.git' \
    --exclude='Formula' \
    --exclude='scripts' \
    "$PLUGIN_DIR/" "$CACHE_DIR/"

  # Get current git commit SHA (or use placeholder if no commits yet)
  GIT_SHA=$(git -C "$PLUGIN_DIR" rev-parse HEAD 2>/dev/null) || GIT_SHA=""
  if [ -z "$GIT_SHA" ] || [ "$GIT_SHA" = "HEAD" ]; then
    GIT_SHA="local-install"
  fi

  NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

  # Update installed_plugins.json
  if [ ! -f "$INSTALLED_JSON" ]; then
    echo '{"version":2,"plugins":{}}' > "$INSTALLED_JSON"
  fi

  PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE_KEY}"
  ENTRY='[{"scope":"user","installPath":"'"$CACHE_DIR"'","version":"'"$PLUGIN_VERSION"'","installedAt":"'"$NOW"'","lastUpdated":"'"$NOW"'","gitCommitSha":"'"$GIT_SHA"'"}]'

  # Use python3 to safely update the JSON (available on macOS by default)
  python3 - "$INSTALLED_JSON" "$PLUGIN_KEY" "$ENTRY" <<'PYEOF'
import sys, json

path = sys.argv[1]
key = sys.argv[2]
entry = json.loads(sys.argv[3])

with open(path) as f:
    data = json.load(f)

data.setdefault("plugins", {})[key] = entry

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

  echo "Done. Plugin installed to: $CACHE_DIR"
  echo ""
  echo "To activate in Claude Code, run: /reload-plugins"
  echo "Skills available as: gh-claude:related, gh-claude:prs, gh-claude:pr-review,"
  echo "                      gh-claude:issue-triage, gh-claude:release-notes, gh-claude:stale-cleanup"
}

main "$@"
