#!/bin/bash
# Installs the outlook skill to ~/.claude/commands/outlook.md
# Reads TEAMS_WEBHOOK_URL, VAULT_MEMORY_PATH, CLAUDE_MEMORY_PATH from .env
# and bakes them into the installed skill.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/commands/outlook.md"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "Error: .env not found. Copy .env.example to .env and fill it in."
  exit 1
fi

# Load .env
set -a
# shellcheck disable=SC1090
source "$SCRIPT_DIR/.env"
set +a

for var in TEAMS_WEBHOOK_URL VAULT_MEMORY_PATH CLAUDE_MEMORY_PATH; do
  if [ -z "${!var}" ]; then
    echo "Error: $var not set in .env"
    exit 1
  fi
done

# Escape | and & for sed since these appear in path/URL substitutions
esc() { printf '%s' "$1" | sed 's/[&|]/\\&/g'; }

sed \
  -e "s|{{TEAMS_WEBHOOK_URL}}|$(esc "$TEAMS_WEBHOOK_URL")|g" \
  -e "s|\$VAULT_MEMORY_PATH|$(esc "$VAULT_MEMORY_PATH")|g" \
  -e "s|\$CLAUDE_MEMORY_PATH|$(esc "$CLAUDE_MEMORY_PATH")|g" \
  "$SCRIPT_DIR/skill.md" > "$DEST"

echo "Installed to $DEST"
