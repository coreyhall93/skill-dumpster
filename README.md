# Skill Dumpster

Native macOS app for browsing and backing up AI-agent skills into the Sol workspace.

Skill Dumpster v2.3 is a Native Premium redesign of the original utility: same local-first scanning and backup behavior, but with a higher-contrast source rail, cleaner detail-first heap workspace, snapshot shelf, inspector/settings swap, Geist typography, springy transitions, a lighter Help surface, and restrained odd-utility personality.

The Swift package lives in `source/`.

## Current Release

- Version: `2.3`
- Build: `5`
- Current release tag: `v2.3.0`
- GitHub: [coreyhall93/skill-dumpster](https://github.com/coreyhall93/skill-dumpster) (private)
- Installed local copy: `~/Applications/Skill Dumpster.app`

## Version Archive

Version 1 is preserved in Git:

```sh
git show v1.0.0
```

The v1 archive commit is `Archive Skill Dumpster v1`. v2.3 replaces the app in place and keeps the same bundle ID, `com.coreyhall.skilldumpster`.

## Open the App

After building, the app bundle is at:

```sh
source/build/Skill Dumpster.app
```

The current packaged build has also been copied to:

```sh
~/Applications/Skill Dumpster.app
```

## Build

```sh
cd source
swift test
Scripts/package_app.sh
open "build/Skill Dumpster.app"
```

To refresh the installed local copy after packaging:

```sh
ditto "source/build/Skill Dumpster.app" "$HOME/Applications/Skill Dumpster.app"
```

## Why This Exists

Skill Dumpster keeps local AI-agent skills visible, inspectable, and backed up as timestamped zip snapshots. It scans Codex, Claude, Grok, plugin/cache, and `~/Sol` skill folders.

The v2.3 design direction is Native Premium first: practical, calm, and Mac-native, with stronger contrast, flatter surfaces, fewer shadows, and oddness kept to copy, motion, empty states, snapshots, and Help.
