#!/bin/bash
# Fires the /outlook skill via Claude Code headless mode.
# Intended to be scheduled by launchd on the user's local machine
# (so the Teams webhook POST originates from the user's IP).
#
# Runs only during 11:00–19:00 local time on weekdays; exits quietly otherwise.

set -e

HOUR=$(date +%H)
DOW=$(date +%u)  # 1=Mon .. 7=Sun

if [ "$DOW" -gt 5 ]; then
  exit 0
fi
if [ "$HOUR" -lt 11 ] || [ "$HOUR" -gt 19 ]; then
  exit 0
fi

LOG_DIR="$HOME/Library/Logs/outlook-digest"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$(date +%Y-%m-%d).log"

{
  echo ""
  echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') — starting ==="
  /Users/ASaeed/.local/bin/claude \
    -p "Run the /outlook skill as a scheduled invocation. Post the email digest directly to Teams without asking for confirmation — but only if there is new non-noise mail in the window. If there are zero new emails, or only noise, DO NOT post to Teams. Do not include the calendar section in the Teams message; calendar data goes to memory only. If a new meeting invite email arrives, surface it in the digest's 📅 MEETING INVITES section. Always perform step 7 (update local calendar memory files) since we're running locally." \
    --allowedTools "Bash,Read,Write,Edit,mcp__claude_ai_Microsoft_365__outlook_calendar_search,mcp__claude_ai_Microsoft_365__outlook_email_search,mcp__claude_ai_Microsoft_365__read_resource"
  echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') — finished (exit $?) ==="
} >> "$LOG" 2>&1
