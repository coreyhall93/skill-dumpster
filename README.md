# Skill Dumpster

Native macOS app for browsing and backing up AI-agent skills to iCloud Drive.

Skill Dumpster v2.3 is a Native Premium redesign of the original utility: same local-first scanning and backup behavior, but with a higher-contrast source rail, cleaner detail-first heap workspace, snapshot shelf, inspector/settings swap, Geist typography, springy transitions, a lighter Help surface, and restrained odd-utility personality.

The Swift package lives in `source/`.

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

## Build

```sh
cd source
swift test
Scripts/package_app.sh
open "build/Skill Dumpster.app"
```

## Why This Exists

Skill Dumpster keeps local AI-agent skills visible, inspectable, and backed up as timestamped zip snapshots. It scans Codex, Claude, Grok, plugin/cache, and `~/Developer` skill folders.

The v2.3 design direction is Native Premium first: practical, calm, and Mac-native, with stronger contrast, flatter surfaces, fewer shadows, and oddness kept to copy, motion, empty states, snapshots, and Help.
