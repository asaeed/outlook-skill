---
name: outlook
description: Use when checking your recent emails or calendar, creating an inbox digest, summarizing what arrived in a time window, or sending an email/calendar summary to Teams.
---

# Outlook Email + Calendar Digest

## Overview
Check today's calendar and recent emails via M365 MCP, write a combined digest, post to Teams, and (for local runs) update Obsidian + Claude memory with calendar data.

## Teams Webhook URL
`{{TEAMS_WEBHOOK_URL}}`

## Workflow

### 1. Fetch Today's Calendar
Use `mcp__claude_ai_Microsoft_365__outlook_calendar_search` to get all events for today (today 00:00 – today 23:59). Sort chronologically. Skip declined events.

For each event, capture: start time, title, duration, key attendees.

All times rendered in Europe/Brussels (CEST during DST / CET otherwise). Append the TZ suffix to every time.

### 2. Search Recent Emails
Use `mcp__claude_ai_Microsoft_365__outlook_email_search` to find emails in the window.
- Manual invocation: default to last 2 hours
- Scheduled: the scheduler passes an explicit `afterDateTime` (carried forward from the last successful run's start time, so no mail is missed across cron drift or laptop sleep). Use it exactly as given — do not compute your own window.

```
afterDateTime: [ISO timestamp]
folderName: Inbox
limit: 50
```

### 3. Read Full Content of Candidates
For emails that look important based on subject/sender, read full body:
```
mcp__claude_ai_Microsoft_365__read_resource
  uri: "mail:///messages/{messageId}"
```

### 4. Categorize Emails

**MEETING** — New meeting invite:
- Detect via iCalendar content-type, or subject starting with "Invitation:", "Updated invitation:", "Canceled:", or body with meeting invite markers
- Surface these in a dedicated 📅 section of the digest

**ACTION** — Needs a response or decision:
- Directly addressed (To:, not just CC:)
- Subject contains: action, review, approve, decision, ASAP, urgent, deadline, please, ?
- From: manager, direct report, cross-functional partner, client contact

**FYI** — No action needed but worth noting:
- Project updates, shared docs, replies in active threads

**NOISE** — Skip entirely:
- Noreply/automated senders
- Newsletter, digest, unsubscribe in body
- System alerts (JIRA, GitHub notifications, calendar notifications)
- CC'd on mass threads with no direct mention

### 5. Format the Email Digest

```
**Email Digest** — [HH:MM]–[HH:MM] CEST

🔴 **ACTION NEEDED** ([count])
• **[Sender name]** — [Subject]: [1-sentence summary of what's needed]

📅 **MEETING INVITES** ([count])
• **[Sender name]** — [Subject] ([when, in Europe/Brussels])

🟡 **FYI** ([count])
• **[Sender name]** — [Subject]

📭 [N] filtered (automated/noise)
```

Rules:
- Omit any section with 0 items
- If ACTION = 0 and no meeting invites: lead with "✅ All clear"
- Keep each ACTION bullet to one line
- **Do not include the calendar section in the Teams digest.** Calendar data goes to memory only (step 7).

### 6. Post to Teams

**Skip this step entirely if there is no new non-noise mail** (i.e. ACTION + MEETING + FYI all zero, or zero emails in window). No Teams message at all in that case.

```bash
python3 - <<'PYEOF'
import json, urllib.request

message = """PASTE_DIGEST_HERE"""

payload = json.dumps({"text": message}).encode("utf-8")
req = urllib.request.Request(
    "WEBHOOK_URL",
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST"
)
with urllib.request.urlopen(req) as r:
    print(r.status, r.read())
PYEOF
```

Replace `PASTE_DIGEST_HERE` with the digest and `WEBHOOK_URL` with the URL above.

### 7. Update Calendar Memory (local runs only)

**This step only applies when invoked locally in a Claude Code session — skip when running as a remote scheduled agent.**

Write today's + tomorrow's calendar events to two locations:

**A. Obsidian vault** — overwrite `$VAULT_MEMORY_PATH/calendar.md`:
```markdown
# Calendar

Last updated: YYYY-MM-DD HH:MM

## Today (Weekday Mon DD)
- HH:MM — Event title (Xh / Xmin, with Person / solo)

## Tomorrow (Weekday Mon DD)
- HH:MM — Event title
```

Fetch tomorrow's events with `mcp__claude_ai_Microsoft_365__outlook_calendar_search` before writing.

**B. Claude auto-memory** — overwrite `$CLAUDE_MEMORY_PATH/calendar_today.md`:
```markdown
---
name: Today's Calendar
description: Your calendar for today and tomorrow, updated by /outlook skill
type: reference
---

[same content as above]
```

Then ensure `MEMORY.md` has an entry for `calendar_today.md`. If missing, add:
`- [calendar_today.md](calendar_today.md) — Today's and tomorrow's calendar events, refreshed by /outlook`

## Manual Invocation
Show the digest in chat first, then ask before posting to Teams.

## Scheduled Invocation
Runs via `run-local.sh` on the local machine (launchd). The runner persists each successful run's start timestamp to `~/Library/Application Support/outlook-digest/last-run.txt` and passes it as `afterDateTime` on the next run, so every run picks up where the last left off — no mail missed across cron drift, laptop sleep, or skipped firings. State is only advanced on exit 0, so a failed run retries the same window. Post directly without confirmation, and still perform step 7 (calendar memory update) since the runner is local, not remote.
