#!/bin/bash
# Fires the /outlook skill via Claude Code headless mode.
# Intended to be scheduled by launchd on the user's local machine
# (so the Teams webhook POST originates from the user's IP).
#
# Runs only during 11:00–19:00 local time on weekdays; exits quietly otherwise.
#
# State: persists the start timestamp after a successful mailbox read and
# accepted Teams delivery if needed. The checkpoint lives at
# ~/Library/Application Support/outlook-digest/last-run.txt and uses it as
# afterDateTime on the next run, so no emails are missed across cron drift,
# laptop sleep, or skipped firings. If state is missing (first run), falls
# back to a 75-minute window.

set -euo pipefail
umask 077
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ${1:-} == --preview ]]; then
  state_file="$HOME/Library/Application Support/outlook-digest/last-run.txt"
  if [[ -s "$state_file" ]]; then
    printf 'Checkpoint: %s\n' "$(cat "$state_file")"
  else
    printf 'Checkpoint missing; existing first-run window is 75 minutes.\n'
  fi
  exit 0
fi

HOUR=$(date +%H)
DOW=$(date +%u)  # 1=Mon .. 7=Sun

if [ "$DOW" -gt 5 ]; then
  exit 0
fi
if [ "$HOUR" -lt 11 ] || [ "$HOUR" -gt 19 ]; then
  exit 0
fi

set -a
source "$HOME/.config/teams-digests/outlook.env"
set +a
: "${TEAMS_WEBHOOK_URL:?Configure the approved Teams workflow}"
test -s "$HOME/.claude-work/commands/outlook.md"

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
  /usr/bin/python3 "$SCRIPT_DIR/run-outlook-digest.py" "$AFTER_ISO" "$START_ISO" "$STATE_FILE"
} >> "$LOG" 2>&1
