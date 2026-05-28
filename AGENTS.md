# Skill Dumpster Agent Notes

Use this file as the routing map before editing the project.

## Documentation Roles

- `README.md` is the user-facing overview, current release summary, and quick build/open instructions.
- `BUILD.md` is the build, package, install, and release checklist.
- `CONTEXT.md` is the durable current-state record: product intent, behavior, design direction, and final release state.
- `PRODUCT_NOTES.md` is the product baseline plus future opportunities and backlog-level thinking.
- `source/README.md` explains the Swift package from inside the source directory.

When changing documentation structure or release state, update this routing file in the same commit.

## Current Release Facts

- App version: `2.3`
- Build: `5`
- Bundle ID: `com.coreyhall.skilldumpster`
- Current tag: `v2.3.0`
- v1 archive tag: `v1.0.0`
- GitHub remote: `https://github.com/coreyhall93/skill-dumpster.git`
- Installed app copy: `~/Applications/Skill Dumpster.app`

## Verification

Before calling a change complete:

```sh
cd source
swift test
Scripts/package_app.sh
```

For release/install updates, refresh the local app copy:

```sh
ditto "build/Skill Dumpster.app" "$HOME/Applications/Skill Dumpster.app"
```

Keep generated build outputs out of Git. They can be recreated from the source package.
