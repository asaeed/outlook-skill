#!/bin/bash
# Installs the outlook skill to ~/.claude/commands/outlook.md
# Reads TEAMS_WEBHOOK_URL from .env and bakes it into the installed skill.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/commands/outlook.md"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "Error: .env not found. Copy .env.example to .env and set TEAMS_WEBHOOK_URL."
  exit 1
fi

# Load .env
set -a
# shellcheck disable=SC1090
source "$SCRIPT_DIR/.env"
set +a

if [ -z "$TEAMS_WEBHOOK_URL" ]; then
  echo "Error: TEAMS_WEBHOOK_URL not set in .env"
  exit 1
fi

# Escape for sed: & and | are special; URL has neither but be safe with |
ESCAPED_URL=$(printf '%s\n' "$TEAMS_WEBHOOK_URL" | sed 's/[&|]/\\&/g')

sed "s|{{TEAMS_WEBHOOK_URL}}|$ESCAPED_URL|g" "$SCRIPT_DIR/skill.md" > "$DEST"
echo "Installed to $DEST"
