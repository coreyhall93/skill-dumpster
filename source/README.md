# Skill Dumpster

Skill Dumpster is a native macOS utility for rummaging through local AI-agent skills and backing them up to iCloud Drive.

Skills are grouped by source:

- `Codex Local` means a skill found in a local Codex skill folder.
- `Claude` means a skill found in Claude's local skills or plugin folders.
- `Grok` means a skill found in Grok's local, bundled, or marketplace-cache folders.
- `Developer` means a skill found under `~/Developer`, including project-local hidden skill folders such as `.claude/skills`.
- `Codex Plugins` means a skill shipped by an installed Codex plugin.
- `Codex System` means a built-in Codex skill.

Status labels keep the dumpster joke while naming real backup state:

- `Fresh Trash` means a skill changed in the last 7 days.
- `Tossed` means a skill is captured in the latest snapshot.

It scans common skill locations:

- `~/.agents/skills`
- `~/.codex/skills`
- `~/.codex/skills/.system`
- `~/.codex/plugins/cache/**/skills`
- `~/.claude/skills`
- `~/.claude/plugins/**/skills`
- `~/.grok/skills`
- `~/.grok/bundled/skills`
- `~/.grok/marketplace-cache/**/skills`
- `~/Developer/**/SKILL.md` including hidden skill folders, with known build/dependency folders pruned.

By default, backups are written as timestamped zip snapshots to:

`~/Library/Mobile Documents/com~apple~CloudDocs/Skill Dumpster/Snapshots`

If iCloud Drive is unavailable, it falls back to:

`~/Documents/Skill Dumpster/Snapshots`

The backup location can be changed from the sidebar Settings view. Custom backup locations are remembered locally and still store snapshots in a `Snapshots` subfolder.

## Build

```sh
swift build
swift test
```

## Package the Mac app

```sh
Scripts/generate_app_icon.sh
Scripts/package_app.sh
open "build/Skill Dumpster.app"
```
