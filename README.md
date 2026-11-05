# Skill Dumpster

A small native Mac app that finds every AI-agent skill (`SKILL.md`) on your machine, shows where each one came from, and backs them all up as zip snapshots.

If you use Claude Code, Codex, Grok, or any agent that reads `SKILL.md` folders, your skills end up spread across hidden folders, plugin caches, and symlinks. Skill Dumpster puts them in one searchable list so a bad plugin update or a stray `rm` never costs you a skill.

## What it does

- **Finds skills everywhere they hide.** It checks these by default:
  - `~/.agents/skills`
  - `~/.claude/skills` and your *installed* Claude Code plugins (read from `installed_plugins.json`, so old cached versions and marketplace catalogs don't show up)
  - `~/.codex/skills`, built-in Codex skills, and Codex plugins
  - Grok's local, bundled, and marketplace skills
  - Any extra folders you add in Settings. These are searched all the way down, including hidden project folders like `.claude/skills`.
- **Shows each skill once.** A skill symlinked into several agents is listed once. Byte-identical copies are merged into one entry that lists where the other copies live.
- **Lets you inspect it.** You get the description, file count, size, last change, content hash, and a preview of `SKILL.md`. Plugin and built-in skills are marked *Managed*, because an update can overwrite local edits to them.
- **Collections.** Group skills you use together, like a project or a workflow. Make one with ⌘N, then drag skills onto it in the sidebar, or use **Add to Collection** in a skill's right-click menu or its Collections button. Right-click a collection to rename it, delete it, or export it as a zip to share. Collections are saved as `collections.json` in your backup folder. Each skill is matched by its path, or by its source and folder name, so collections survive plugin updates and work on any Mac that syncs that folder.
- **Backs it up.** One click (⇧⌘B) saves a timestamped zip of every skill plus a `manifest.json`. Snapshots go to `~/Documents/Skill Dumpster/Snapshots` by default, or to any folder you choose.

Two status filters use the dumpster lingo:

- **Fresh Trash** shows skills changed in the last 7 days.
- **Tossed** shows skills unchanged since your latest snapshot.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or the Swift 6 toolchain, to build

## Build and run

```sh
git clone https://github.com/coreyhall93/skill-dumpster.git
cd skill-dumpster/source
swift test
Scripts/package_app.sh
open "build/Skill Dumpster.app"
```

To install it, copy the bundle into Applications:

```sh
ditto "build/Skill Dumpster.app" "$HOME/Applications/Skill Dumpster.app"
```

The build is signed ad hoc, not notarized. If you move it to another Mac, Gatekeeper will ask you to approve it in System Settings › Privacy & Security.

## Project layout

```
source/
  Package.swift
  Sources/SkillDumpsterCore/   Scanning, de-duplication, snapshots. No UI.
  Sources/SkillDumpster/       SwiftUI app.
  Tests/SkillDumpsterCoreTests/
  Scripts/package_app.sh       Builds the .app bundle (version lives here).
  Scripts/generate_app_icon.sh Rebuilds AppIcon.icns from the SVG (needs rsvg-convert).
```

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘N | New collection |
| ⌘R | Rescan skill folders |
| ⇧⌘B | Back up all skills |
| ⌘F | Search |
| ⌘, | Settings |
| ⌘? | Help |

## License

MIT. See [LICENSE](LICENSE). The app icon is based on the Tabler Icons `trash` glyph (MIT); see [source/THIRD_PARTY_NOTICES.md](source/THIRD_PARTY_NOTICES.md).
