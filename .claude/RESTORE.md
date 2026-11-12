# Claude Code config backup — 2026-11-10

Made by Claude Code (Opus 5.5) to reset the user's Claude Code configuration to a fresh-install state.
Machine: Windows 11, home = `C:\Users\luibaia`. Paths inside this folder mirror their original
location relative to the home directory.

## Backed-up items

| # | Backup path (relative to this folder) | Original absolute path | What it is | SHA-256 |
|---|---|---|---|---|
| 1 | `.claude/settings.json` | `C:\Users\luibaia\.claude\settings.json` | Claude Code user-scope settings (`autoUpdatesChannel: "latest"`, `theme: "auto"`) | `b2bbc8abb8828993e3f46e7344137282729d181ab4bd7f6965ff7dbd07f9d8e8` |

That is the complete list. Nothing else was moved.

## Restore

Before restoring, check whether Claude Code has created a new `C:\Users\luibaia\.claude\settings.json`
since the backup (it does so when you change an option in `/config`). If it exists, do not overwrite it
blindly: merge the keys from the backup copy into it, and keep the newer file's values on conflicts unless
the user says otherwise.

Git Bash:

```bash
B=~/agent-config-backup-2026-11-10
if [ -e ~/.claude/settings.json ]; then
  echo "settings.json already exists, merge by hand:"; cat ~/.claude/settings.json
else
  mv "$B/.claude/settings.json" ~/.claude/settings.json
fi
sha256sum ~/.claude/settings.json   # expect b2bbc8ab...d9e8 if nothing was merged
```

PowerShell:

```powershell
$B = "$env:USERPROFILE\agent-config-backup-2026-11-10"
if (Test-Path "$env:USERPROFILE\.claude\settings.json") {
  Write-Output "settings.json already exists, merge by hand"
} else {
  Move-Item "$B\.claude\settings.json" "$env:USERPROFILE\.claude\settings.json"
}
(Get-FileHash "$env:USERPROFILE\.claude\settings.json").Hash
```

Claude Code reloads settings files without a restart. Run `/status` and confirm `Setting sources`
lists "User settings". When the file is back in place and verified, this backup folder can be deleted.

## Left in place on purpose (not part of this backup)

- `~/.claude/.credentials.json`, `~/.claude.json`: login, account and app state. The user asked to stay signed in. `~/.claude.json` has no user MCP servers; the per-project `mcpServers` for this repo is `{}`.
- `~/.claude/skills/synced/`, `~/.claude/plugins/synced/`: skills and the GitHub plugin synced from the claude.ai account. They download again automatically, so moving them would have no effect.
- `~/.claude/plugins/marketplaces/claude-plugins-official`, `known_marketplaces.json`: the official marketplace, which Claude Code installs automatically.
- `~/.claude/projects/*/memory/`: auto-memory folders, both empty.
- Session and app data (`history.jsonl`, `projects/*.jsonl`, `file-history`, `backups`, `cache`, `daemon`, `jobs`, `sessions`, `session-env`, `shell-snapshots`, `paste-cache`, `downloads`, `spares`).
- Files committed to the repo `C:\dfds\AIHero\ai-coding-crash-course` (`.claude/skills` → `.agents/skills` symlink with only `.gitkeep`, `request-logger/CLAUDE.md`): project source, left untouched.
