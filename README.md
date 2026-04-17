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
- `.env` — local-only, holds `TEAMS_WEBHOOK_URL` (gitignored)
- `install.sh` — substitutes the URL and writes to `~/.claude/commands/outlook.md`
