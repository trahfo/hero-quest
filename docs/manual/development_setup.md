# Development Setup (mise)

All dev workflows run through [mise](https://mise.jdx.dev). `mise.toml` in the project root defines tools, env vars, and tasks.

## Install

```bash
brew install mise          # or see https://mise.jdx.dev/getting-started.html
cd god
mise trust                 # once, to allow this project's mise.toml
mise install               # installs uv and gdtoolkit (gdlint / gdformat)
```

You also need Godot 4.7 (the project targets `4.7`, Mobile renderer). The default path is `/Applications/Godot.app/Contents/MacOS/Godot`.

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `GODOT_BIN` | `/Applications/Godot.app/Contents/MacOS/Godot` | Godot executable used by every task |
| `PROJECT_PATH` | project root (`config_root`) | Passed as `--path` |

Override on another machine or for another Godot build:

```bash
GODOT_BIN=/usr/local/bin/godot mise run test
```

## Tasks

List them any time with `mise tasks`.

| Task | What it does |
|---|---|
| `mise play` | Launch the game (start menu) |
| `mise run editor` | Open the Godot editor |
| `mise run test` | Headless run of all test suites (`scripts/test_hero_quest.gd`). Fails on any assertion, including ADR 0001 size limits |
| `mise run check` | Headless parse check (`scripts/dev/check_all.gd`): loads every GDScript and fails on compile errors |
| `mise run import` | Headless asset re-import; refreshes the `.godot` cache and UIDs. Run after a fresh clone or `clean` |
| `mise run line-limits` | ADR 0001 check: fail over 400 lines, warn over 250 |
| `mise run lint` | `gdlint` (advisory: always exits 0; config in `.gdlintrc`) |
| `mise run format` | `gdformat scripts` (rewrites files; review the diff) |
| `mise run clean` | Delete `.godot/` |

## Notes

- Godot 4.7 may print `recursive_mutex lock failed` / SIGABRT when quitting headless after a clean run. The `test` task judges by the suite's own verdict, so this is harmless.
- `gdtoolkit` cannot parse every Godot 4.7 construct (e.g. one-line lambdas with inline `if`), which is why `lint` is advisory.
- Recommended before committing: `mise run check && mise run test && mise run line-limits`.
