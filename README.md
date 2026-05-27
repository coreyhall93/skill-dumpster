# Skill Dumpster

Native macOS app for browsing and backing up AI-agent skills to iCloud Drive.

The Swift package lives in `source/`.

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
