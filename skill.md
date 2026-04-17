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
- Scheduled: last 75 minutes (overlap allowed — cron drift protection)

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

**ACTION** — Needs a response or decision:
- Directly addressed (To:, not just CC:)
- Subject contains: action, review, approve, decision, ASAP, urgent, deadline, please, ?
- From: manager, direct report, cross-functional partner, client contact

**FYI** — No action needed but worth noting:
- Meeting invites, project updates, shared docs, replies in active threads

**NOISE** — Skip entirely:
- Noreply/automated senders
- Newsletter, digest, unsubscribe in body
- System alerts (JIRA, GitHub notifications, calendar notifications)
- CC'd on mass threads with no direct mention

### 5. Format the Combined Digest

```
📅 **Today's Calendar** (Europe/Brussels)
• [HH:MM CEST] — [Event title] ([duration])

---

**Email Digest** — [HH:MM]–[HH:MM] CEST

🔴 **ACTION NEEDED** ([count])
• **[Sender name]** — [Subject]: [1-sentence summary of what's needed]

🟡 **FYI** ([count])
• **[Sender name]** — [Subject]

📭 [N] filtered (automated/noise)
```

If ACTION count is 0, lead with "✅ All clear" before FYI.
If no emails in window: skip email sections, write "📭 No new emails."
If no meetings: `📅 No meetings today.`

### 6. Post to Teams

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
Post directly without confirmation. Skip step 7 (can't write to local files).
