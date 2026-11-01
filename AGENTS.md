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

## Dev tooling (mise)
Use [mise](docs/manual/development_setup.md) for all workflows instead of calling Godot by hand (it honors `GODOT_BIN`):
- `mise run test`: headless test suites (run before finishing any change)
- `mise run check`: headless parse check of every script
- `mise run line-limits`: ADR 0001 size check
- `mise play` / `mise editor`: launch the game / editor
- `mise run import`: refresh the `.godot` cache; `mise run lint` / `mise run format`: gdtoolkit

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

## Architecture, Level Generation & System Manuals

### Level Architect Skill & Level Generation
When prompted to generate an entire new level, add a new room, connect corridors, or create procedural materials and props, use the dedicated **`level-architect`** skill ([`.agents/skills/level-architect/SKILL.md`](.agents/skills/level-architect/SKILL.md)). It contains the comprehensive geometry formulas, material catalog, prop clearance tables, and JSON level recipes.

### Hero Quest 3D System Manual & Specifications
Detailed user guides and technical specifications for gameplay features, tools, and character systems are organized under [**`docs/manual/index.md`**](docs/manual/index.md):
- **[Level Editor Specification & Guide](docs/manual/editor_guide.md)**: Tools, 80% ghost preview, 90° hover rotation, line dragging, and contextual two-stage deletion.
- **[Character Systems, Archetypes & Locomotion](docs/manual/character_systems.md)**: Archetype hot-swapping (1..4), continuous multi-tile locomotion, the strict **Anatomical Knee Flexion Law** (`Shin.rotation.x <= 0.0`), and camera-relative isometric input quadrant mapping.
- **[Character Sheet, Inventory & Gameplay](docs/manual/inventory_and_gameplay.md)**: Character sheet (`C` key), equipment slots, item rarities, loot dialogs, 3D dropped floor items (`HeroQuestFloorItem`), and the start menu level browser.

### Abstract Architectural Invariants
All procedural architecture and tile-based placement must maintain the following core invariants defined in [docs/tile_positioning_ruleset.md](docs/tile_positioning_ruleset.md):
- **Continuous Documentation Persistence**:
  - Whenever the user specifies architectural, geometric, or spatial constraints, persist the generalized rule into [docs/tile_positioning_ruleset.md](docs/tile_positioning_ruleset.md) and update the `level-architect` skill.
  - Whenever the user specifies editor workflows, UI controls, character mechanics, or gameplay features, persist the documentation into the appropriate section of [docs/manual/](docs/manual/index.md).
- **Floor Substrates**: Every wall tile and arch pier must have a solid stone floor tile instantiated directly beneath it (`y = 0.0m`, thickness `0.28m`).
- **Wall Thickness**: Strict `0.9m` matching column shafts (`0.9m x 0.9m`). Never 2.0m cubic blocks.
- **Wall Connections**: Modular walls dynamically compute straight (X/Z), L-corners (with exterior ashlar quoins), T-junctions, and 4-way cross junctions. Modular wall arms must never protrude into walkable cells.
- **Arch Spans**: Ends must land squarely on column capitals (`spring_height = 3.6m`, span = `2.0 * TILE_SIZE` for 3-tile, `3.0 * TILE_SIZE` for 4-tile). Door piers extend by `0.55m` along `extend_dir` to touch adjoining walls seamlessly.
- **Corridor Matching**: Corridors must match arch portal widths, and doorways between rooms must match on both ends.
- **Windows**: Dedicated 0.9m wall tiles with embrasure reveals on straight runs only. Prohibited in corners, on door piers, or between indoor rooms. Zero z-fighting.
- **Furniture & Decors**: Flat-backed furniture rotated against walls. Tables must have chairs and keep clear of carpets. Wall torches mount at `y = 2.2m` on solid wall piers (never on windows).

