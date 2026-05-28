# Skill Dumpster Context

Built with Codex on May 27, 2026.

Version 1 was archived before the v2 redesign with Git commit `Archive Skill Dumpster v1` and tag `v1.0.0`.

The current finalized release is v2.3 build 5, committed as `Redesign Skill Dumpster v2.3`, tagged `v2.3.0`, pushed to the private GitHub repo `coreyhall93/skill-dumpster`, and copied locally to `~/Applications/Skill Dumpster.app`.

## Product Intent

Skill Dumpster is a small, polished Mac utility for people who rely heavily on AI-agent skills and want a local, inspectable, iCloud-backed safety net.

## Current Behavior

- Scans common local skill locations:
  - `~/.agents/skills`
  - `~/.codex/skills`
  - `~/.codex/skills/.system`
  - `~/.codex/plugins/cache`
  - `~/.claude/skills`
  - `~/.claude/plugins`
  - `~/.grok/skills`
  - `~/.grok/bundled/skills`
  - `~/.grok/marketplace-cache`
  - `~/Developer`
- Resolves symlinked roots, including the current `~/Developer` symlink into iCloud Drive.
- Includes hidden project-local skill folders during `~/Developer` scans while pruning known build, dependency, and VCS folders.
- Shows skills in a three-pane native SwiftUI interface.
- Follows system appearance instead of forcing dark mode.
- Uses the installed Geist font family.
- Creates timestamped zip snapshots in iCloud Drive under `Skill Dumpster/Snapshots`, with a Documents fallback.
- Supports changing the backup folder from sidebar Settings; custom folders are remembered locally and use a `Snapshots` subfolder.
- Supports deleting snapshots from the GUI with confirmation.
- Supports a compact sidebar mode that keeps only the navigation icons visible.
- Keeps refresh and backup as toolbar actions; settings now live in the sidebar and replace the source list with a compact settings panel.
- Provides a lightweight `Skill Dumpster Help` window from the macOS Help menu and Settings sidebar.
- Shows the selected source/status name in the list header with an info affordance, and shifts the current count to the right.
- Labels skill grouping as source/origin (`Codex Local`, `Claude`, `Grok`, `Developer`, `Codex Plugins`, `Codex System`) instead of implying editable metadata.
- Separates sidebar source filters from status filters (`Fresh Trash`, `Tossed`). Fresh Trash means changed in the last 7 days; Tossed means captured in the latest snapshot.
- Marks plugin/system skills as managed instead of read-only. They are still editable on disk, but may be owned or overwritten by Codex/plugin installation workflows.
- Provides `Reveal`, `Edit`, and `Back Up` actions for the selected skill. `Edit` opens the selected `SKILL.md`; computed stats such as file count, size, modified date, and hash are intentionally read-only.
- Includes a placeholder macOS app icon generated from a Tabler Icons trash glyph.

## Design Direction

v2.3 follows the local Quiet Delight design principles with a Native Premium structure: reduce friction, make the app feel instant, use readable typography as the foundation, keep chrome restrained, and break away from the original three-pane screenshot shell with a compact high-contrast source rail, cleaner detail-first heap workspace, snapshot shelf, inspector/settings swap, and visible but non-blocking odd utility moments.

The target is still the frictionless Mac feel of polished native utilities: quiet controls, fast row selection, comfortable reading, restrained surfaces, and enough character to feel owned rather than generic. Skill Dumpster should feel like an odd little utility, not a novelty skin.

## Documentation Intent

These docs should stand on their own for a technically competent person with no prior context. Keep current-state facts in this file, build/install commands in `BUILD.md`, user-facing overview in `README.md`, and future product opportunities in `PRODUCT_NOTES.md`.
