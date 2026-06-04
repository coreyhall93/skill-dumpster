# Skill Dumpster Product Notes

## Current Product Shape

Skill Dumpster v2.3 is currently a local skill browser and backup utility with a Native Premium Mac interface. It is useful for:

- Finding skills across known local sources.
- Inspecting a skill's description, path, size, modified date, file count, and content hash.
- Opening a skill in Finder.
- Opening `SKILL.md` for editing.
- Creating and deleting Sol-backed zip snapshots.
- Reviewing source meanings, backup behavior, dumpster lingo, and shortcuts from the lightweight Help window.

The v2.3 redesign keeps the v1 feature set intact while breaking the original three-pane screenshot shell: compact high-contrast source rail, cleaner detail-first heap workspace, snapshot shelf, inspector/settings swap, warmer neutral palette, flatter surfaces, more comfortable line spacing, clearer sidebar/source semantics, spring-based transitions, and small status moments such as "Tossed" backup completion.

Version 1 remains archived as Git tag `v1.0.0`.

The current v2.3 release is tagged `v2.3.0`, pushed to the private GitHub repo `coreyhall93/skill-dumpster`, and installed locally at `~/Applications/Skill Dumpster.app`.

## What It Needs To Feel Complete

### 1. Source Management

The app should let the user add, remove, enable, disable, and label skill roots from the GUI.

Examples:

- Codex skills
- Claude skills
- Grok or other agent folders
- Any custom folder that contains `SKILL.md` files

This is the biggest missing piece if the promise is "manage all skills no matter where they live."

Today, source labels are derived from hard-coded scanner roots in `SkillScanner.defaultRoots`. The built-in sources cover Codex, Claude, Grok, plugin caches, and `~/Sol`, but they are not editable from the GUI yet.

### 2. Skill Actions

The app should support direct actions on skills:

- Edit `SKILL.md`
- Reveal folder
- Copy path
- Duplicate skill
- Move skill to another source
- Archive or disable a skill
- Validate skill metadata

Deleting should be deliberate and probably require confirmation.

### 3. Snapshot Restore

Snapshots are currently backup-only. A complete app needs restore flows:

- Browse snapshot contents
- Compare current skill vs snapshot version
- Restore one skill
- Restore all skills
- Export a snapshot elsewhere

### 4. Duplicate And Conflict Detection

The app already hashes skill contents, so it can grow into:

- Duplicate skill detection
- Same slug in multiple sources
- Same content with different names
- Changed since last snapshot
- Missing from latest snapshot

### 5. Search That Feels Like A Library

Search should eventually include:

- Skill body text
- Source path
- Tags/front matter
- Recently edited
- Broken or invalid skills

### 6. Editing Safety

If the app edits skills directly, it should protect the user:

- Automatic pre-edit snapshot
- Validation before save
- Revert unsaved changes
- Show parse errors clearly

### 7. App Preferences

Settings should graduate from a popover into a real preferences surface when these exist:

- Backup destination
- Auto-backup frequency
- Sources
- Backup/sync status
- Excluded folders
- Theme behavior

## Product Positioning

The strongest version of Skill Dumpster is not just "backup my Codex skills."

It is:

> A local skill library manager for every AI agent on your Mac.

That means the core noun should become "source" rather than "kind", and the core workflow should be:

1. Add sources.
2. Browse and edit skills.
3. See what changed.
4. Back up or restore with confidence.
