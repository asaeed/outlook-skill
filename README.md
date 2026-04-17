# outlook-skill

Outlook email + calendar digest skill for Claude Code. Fetches recent mail and today's calendar via the Microsoft 365 MCP and posts a digest to Teams.

## Install

```bash
cp .env.example .env
# edit .env, set TEAMS_WEBHOOK_URL
./install.sh
```

Installs to `~/.claude/commands/outlook.md`. The webhook URL is baked in at install time so it never touches the source repo.

## Files

- `skill.md` — source skill template (uses `{{TEAMS_WEBHOOK_URL}}` placeholder)
- `.env` — local-only, holds `TEAMS_WEBHOOK_URL` and memory paths (gitignored)
- `install.sh` — substitutes placeholders and writes to `~/.claude/commands/outlook.md`
- `run-local.sh` — headless wrapper for scheduling via launchd/cron; fires `claude -p` with the skill

## Scheduling locally (launchd)

The Teams Incoming Webhook connector in many tenants is IP-allowlisted and rejects posts from cloud runners (`403: Host not in allowlist`). Running on your own machine avoids that.

Create `~/Library/LaunchAgents/com.<user>.outlook-digest.plist` that invokes `run-local.sh` on a cron-style schedule. The wrapper self-gates to weekdays 11:00–19:00 local, so a plist that fires every hour is fine.

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.<user>.outlook-digest.plist
```

Logs land in `~/Library/Logs/outlook-digest/YYYY-MM-DD.log`.
