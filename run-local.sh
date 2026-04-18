#!/bin/bash
# Fires the /outlook skill via Claude Code headless mode.
# Intended to be scheduled by launchd on the user's local machine
# (so the Teams webhook POST originates from the user's IP).
#
# Runs only during 11:00–19:00 local time on weekdays; exits quietly otherwise.
#
# State: persists the start timestamp of the last successful run to
# ~/Library/Application Support/outlook-digest/last-run.txt and uses it as
# afterDateTime on the next run, so no emails are missed across cron drift,
# laptop sleep, or skipped firings. If state is missing (first run), falls
# back to a 75-minute window.

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

STATE_DIR="$HOME/Library/Application Support/outlook-digest"
STATE_FILE="$STATE_DIR/last-run.txt"
mkdir -p "$STATE_DIR"

# Capture this run's start time BEFORE invoking claude so that emails arriving
# during the run are still picked up on the next run.
START_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -f "$STATE_FILE" ] && [ -s "$STATE_FILE" ]; then
  AFTER_ISO=$(cat "$STATE_FILE")
else
  # First run — fall back to 75 minutes ago
  AFTER_ISO=$(date -u -v-75M +"%Y-%m-%dT%H:%M:%SZ")
fi

{
  echo ""
  echo "=== $START_ISO — starting (afterDateTime=$AFTER_ISO) ==="
  set +e
  /Users/ASaeed/.local/bin/claude \
    -p "Run the /outlook skill as a scheduled invocation. Post the email digest directly to Teams without asking for confirmation — but only if there is new non-noise mail in the window. If there are zero new emails, or only noise, DO NOT post to Teams. Do not include the calendar section in the Teams message; calendar data goes to memory only. If a new meeting invite email arrives, surface it in the digest's 📅 MEETING INVITES section. For the email search, use afterDateTime='$AFTER_ISO' exactly as given (do NOT compute your own window — this was provided by the scheduler to pick up from the last run and avoid missing mail). Always perform step 7 (update local calendar memory files) since we're running locally." \
    --allowedTools "Bash,Read,Write,Edit,mcp__claude_ai_Microsoft_365__outlook_calendar_search,mcp__claude_ai_Microsoft_365__outlook_email_search,mcp__claude_ai_Microsoft_365__read_resource"
  EXIT=$?
  set -e
  echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') — finished (exit $EXIT) ==="
  if [ "$EXIT" -eq 0 ]; then
    echo "$START_ISO" > "$STATE_FILE"
    echo "state: advanced last-run to $START_ISO"
  else
    echo "state: NOT advanced (claude exited $EXIT) — next run will re-read from $AFTER_ISO"
  fi
} >> "$LOG" 2>&1
