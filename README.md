# Hero Quest 3D (`god`)

A Godot 4.7 (Mobile renderer, Jolt Physics) 3D dungeon crawler in the spirit of HeroQuest: procedural castle levels, an in-game level editor, line-of-sight with fog of war, interactive doors, loot, and mini-games.

## Quick start

```bash
brew install mise
mise trust && mise install
mise run import     # first time only
mise play           # play the game
mise run editor     # open in the Godot editor
mise run test       # headless test suites
```

Set `GODOT_BIN` if Godot is not at `/Applications/Godot.app/Contents/MacOS/Godot`.

## Documentation

- [Manual & system docs](docs/manual/index.md)
- [Development setup (mise tasks)](docs/manual/development_setup.md)
- [Architecture decision: class size limits](docs/adr/0001-gdscript-modularity-and-class-size-limits.md)
- [Tile positioning ruleset](docs/tile_positioning_ruleset.md)

In game: `TAB` level editor, `F` fog of war, `1-4` archetypes, `Q`/`E`/wheel zoom, `R` rotate camera.
