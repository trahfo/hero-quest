# Godot Project Guidelines

This workspace is a Godot 4 project (`god`).

## Godot MCP Integration
The `godot` MCP server ([Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)) is installed and configured.

- **Godot Executable**: `/Applications/Godot.app/Contents/MacOS/Godot` (Godot 4.x)
- **Project Path**: `/Users/jakob/Workspace/god`

### Available MCP Capabilities
- `launch_editor`: Open the Godot editor for this project.
- `run_project`: Run the Godot project and capture debug output/errors.
- `stop_project`: Stop running the project.
- `get_debug_output`: Inspect runtime errors and logs.
- `create_scene`: Create new scene files (`.tscn`).
- `add_node`: Add nodes to scenes with specific properties.
- `load_sprite`: Load sprites/textures into `Sprite2D` nodes.
- `export_mesh_library`: Export 3D scenes as `MeshLibrary` for `GridMap`.
- `save_scene`: Save scene modifications or create variants.
- `get_uid` / `update_project_uids`: Manage file UIDs for Godot 4.4+.

When calling Godot MCP tools, provide `projectPath: "/Users/jakob/Workspace/god"`.

## Architectural Guidelines & Code Size Limits
To keep the codebase maintainable, modular, and easy for humans and AI agents to extend, follow [ADR 0001: GDScript Modularity, Class Size Limits, and Component Architecture](docs/adr/0001-gdscript-modularity-and-class-size-limits.md):

1. **File Size Budget**:
   - Aim for standard GDScript classes to stay below **250 lines**.
   - **Hard Ceiling**: No GDScript file should exceed **400 lines**. If a file approaches 400 lines, decompose it immediately into focused collaborators (Builders, Factories, Components, or Strategy classes).
2. **Component Pattern for Interactions**:
   - Interactive objects in the world must attach a dedicated component (`HeroQuestInteractable`).
   - Actors (e.g. player, NPC) must never check hardcoded node names (`prop.name == "..."`) or manipulate external prop children directly. Actors simply invoke `interact(actor, context)`.
3. **Procedural Systems Separation**:
   - Separate material creation (`*Materials`), geometry/mesh generation (`*MeshBuilder`), prop assembly (`*PropFactory`), and room/zone sequencing (`*ZonePlanner`).
   - Use a lightweight Facade to coordinate these systems and expose a clean, backwards-compatible public API.
4. **Audio DSP vs Audio Playback**:
   - Keep procedural waveform synthesis and PCM byte generation isolated in dedicated synthesizer classes (`*AudioSynth`).
   - Audio managers should focus purely on playback pools, audio buses, and triggering events.

## Tile & Prop Positioning Ruleset
For all procedural architecture, grid placement, wall modeling, arch calculations, and furniture rules, follow [docs/tile_positioning_ruleset.md](docs/tile_positioning_ruleset.md):
- **Continuous Ruleset Persistence**: Whenever the user requests a change, correction, or constraint regarding the positioning, dimensions, clearance, rotation, or alignment of objects, tiles, or props, **always persist the generalized rule into [docs/tile_positioning_ruleset.md](docs/tile_positioning_ruleset.md)** for future reference and enforce it across all subsequent tasks.
- **Wall Thickness**: Strict `0.9m` matching column shafts. Never 2.0m cubic blocks.
- **Wall Types**: Dynamic straight (X/Z), L-corners, T-junctions, and 4-way cross junctions via `CastleWallTileFactory.create_modular_wall`.
- **Perimeter Sealing**: Filter by room tile type, not `walkable`. Collect both orthogonal and diagonal neighbors to seal zig-zag walls.
- **Arch Spans**: Ends must land squarely on column capitals (`spring_height = 3.6m`, span = `2.0 * TILE_SIZE` for 3-tile, `3.0 * TILE_SIZE` for 4-tile).
- **Door Columns**: Extend by `0.55m` along `extend_dir` to touch adjacent walls seamlessly.
- **Windows**: Dedicated 0.9m wall tiles with corner reveals. Never place windows in corners. Zero z-fighting.
- **Props**: Wall furniture rotated flat against walls. Tables must have chairs and keep clear of carpets. Cursor elevated at `y = 0.035` with `render_priority = 2`.
