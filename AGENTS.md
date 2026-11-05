# Notes for coding agents

- The Swift package lives in `source/`. Core logic (`SkillDumpsterCore`) has no UI and is covered by tests. Keep new scanning or backup behavior there, with a test.
- Before calling a change done, run `swift test` and `Scripts/package_app.sh` from `source/`.
- The app version and build number live in `source/Scripts/package_app.sh`.
- Don't hard-code paths from one person's machine. Machine-specific folders belong in Settings (user defaults), not in the default scan roots.
- `build/` and `.build/` are generated. Keep them out of Git.
