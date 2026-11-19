# outlook-skill

Outlook email + calendar digest skill for Claude Code. Fetches recent mail and today's calendar via the Microsoft 365 MCP and posts a digest to Teams.

## Install

```bash
./install.sh <claude-work|claude-personal>
```

Installs to `<profile config dir>/commands/outlook.md` (`~/.claude-work` or `~/.claude`) and bakes in that profile's Claude memory path. The Teams webhook is never baked in: the skill reads `TEAMS_WEBHOOK_URL` from the environment at run time (`run-local.sh` loads it from `~/.config/teams-digests/outlook.env`, owner-only).

## Files

- `skill.md` — source skill template (uses `$CLAUDE_MEMORY_PATH` placeholder)
- `install.sh <profile>` — substitutes placeholders and writes to the profile's `commands/outlook.md`
- `run-local.sh` — headless wrapper for scheduling via launchd/cron; fires `claude-work -p` with the skill, loading `TEAMS_WEBHOOK_URL` from `~/.config/teams-digests/outlook.env`
- `run-outlook-digest.py` — called by `run-local.sh`: runs `claude-work -p`, checks the Inbox read covered the requested window, and advances the checkpoint only after an empty/noise-only read or an accepted Teams post

## Scheduling locally (launchd)

The Teams Incoming Webhook connector in many tenants is IP-allowlisted and rejects posts from cloud runners (`403: Host not in allowlist`). Running on your own machine avoids that.

Create `~/Library/LaunchAgents/com.<user>.outlook-digest.plist` that invokes `run-local.sh` on a cron-style schedule. The wrapper self-gates to weekdays 11:00–19:00 local, so a plist that fires every hour is fine.

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.<user>.outlook-digest.plist
```

Logs land in `~/Library/Logs/outlook-digest/YYYY-MM-DD.log`.
