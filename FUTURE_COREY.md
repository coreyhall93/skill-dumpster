# Future Corey: Skill Dumpster

Updated: 2026-05-28

## What This Is

Skill Dumpster is a native macOS app for finding local AI-agent skills and backing them up as timestamped zip snapshots in the Sol workspace (`~/Sol/02-Projects/skill-dumpster/Snapshots`).

## Current State

- Current release: v2.3 build 5.
- Source Swift package lives in `source/`.
- Installed local copy: `~/Applications/Skill Dumpster.app`.
- Private GitHub repo recorded in `README.md`.
- v1 is archived in Git with tag `v1.0.0`.

## Next Move

Build and open:

```sh
cd "$HOME/Sol/02-Projects/skill-dumpster/source"
swift test
Scripts/package_app.sh
open "build/Skill Dumpster.app"
```

Refresh installed copy:

```sh
ditto "build/Skill Dumpster.app" "$HOME/Applications/Skill Dumpster.app"
```

## Gotchas

- Keep generated `build/` and `.build/` outputs out of Git.
- Do not copy the Calendar Bridge UI structure into this app or vice versa; they should remain distinct products.
- Current v2.3 design is Native Premium: practical, calm, Mac-native, with restrained odd utility personality.

## Deeper Docs

- `README.md` - release and quick commands.
- `BUILD.md` - package/install checklist.
- `CONTEXT.md` - product behavior and design direction.
- `PRODUCT_NOTES.md` - future opportunities.
