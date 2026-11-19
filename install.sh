#!/bin/bash
# Installs the outlook skill into one Claude profile.
# Usage: ./install.sh <claude-work|claude-personal>
# Bakes the profile's Claude memory path into the installed command. The Teams
# webhook is NOT baked in: the skill reads TEAMS_WEBHOOK_URL from the
# environment at run time.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Claude keys project memory by launch dir: / becomes - (claude-work starts in ~/glg, claude-personal in ~/personal)
case "${1:-}" in
  claude-work)     CONFIG="$HOME/.claude-work"; LAUNCH="$HOME/glg" ;;
  claude-personal) CONFIG="$HOME/.claude";      LAUNCH="$HOME/personal" ;;
  *) echo "Usage: $0 <claude-work|claude-personal>  (Codex has no M365 connector, so no Codex target)" >&2; exit 2 ;;
esac
DEST="$CONFIG/commands/outlook.md"
CLAUDE_MEMORY_PATH="$CONFIG/projects/$(printf '%s' "$LAUNCH" | tr '/' '-')/memory"

mkdir -p "$(dirname "$DEST")"
sed "s|\$CLAUDE_MEMORY_PATH|$CLAUDE_MEMORY_PATH|g" "$SCRIPT_DIR/skill.md" > "$DEST"
echo "Installed to $DEST (memory: $CLAUDE_MEMORY_PATH)"
