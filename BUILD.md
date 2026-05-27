# Skill Dumpster Build Notes

## Requirements

- macOS
- Xcode command line tools or Xcode
- Swift Package Manager

## Commands

```sh
cd ~/Developer/AI-Brain/02-Projects/skill-dumpster/source
swift test
Scripts/generate_app_icon.sh
Scripts/package_app.sh
```

The packaging script creates:

```sh
build/Skill Dumpster.app
```

Generated build directories are intentionally ignored by git-style tooling:

- `.build/`
- `build/`

They can be recreated from source at any time.
