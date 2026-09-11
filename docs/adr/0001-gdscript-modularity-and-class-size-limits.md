# ADR 0001: GDScript Modularity, Class Size Limits, and Component Architecture

## Status
Accepted

## Context
As gameplay features and visual systems expanded in the Godot 4 project (notably in the Hero Quest prototype), several GDScript files grew into monolithic "God Objects." 

Specific pain points observed:
1. `scripts/hero_quest/castle_builder.gd` grew to 1,340 lines, simultaneously handling material shading definitions, 2D/3D coordinate transformations, spatial walkability grids, procedural geometric mesh creation (curved arches, wall segments, piers), entity and lighting assembly, and level layout for 7 distinct zones.
2. `scripts/hero_quest/hero_box.gd` handled player hopping physics while hardcoding knowledge of external interactive objects (`prop.name == "BlacksmithAnvil"`, `prop.has_meta("is_chest")`) and driving their animations directly, violating the Single Responsibility and Open-Closed principles.
3. `scripts/hero_quest/hero_quest_audio.gd` intermingled runtime audio player pooling and volume control with byte-level procedural PCM audio synthesis math.

Consequences of this monolithic structure included high cognitive load, elevated risk of regressions, difficulty in testing sub-systems independently, and friction when adding new world features.

## Decision

To maintain code quality, maintainability, and architectural clarity, we adopt the following standards for all GDScript files in this project:

### 1. Class Size & Complexity Budgets
- **Target Size**: Standard GDScript classes should be under **250 lines**.
- **Hard Ceiling**: No single GDScript file shall exceed **400 lines**.
- When a class approaches or exceeds 400 lines, it is an architectural code smell indicating mixed responsibilities. It MUST be decomposed into focused collaborators.

### 2. Component Pattern for World Interactions
- Interactive objects (chests, anvils, altars, bells, doors, switches) must attach a dedicated component (`HeroQuestInteractable` or `Interactable3D`).
- Actors (players, NPCs) must NEVER check hardcoded node names (e.g. `prop.name == "Anvil"`) or directly mutate an external object's visual children.
- Instead, actors query the interactable component and call `interact(actor, context)`. The interactable manages its own state, animations, sounds, and signals.

### 3. Builder, Factory, and Facade Patterns for Procedural Systems
- Procedural generation systems must be partitioned by concern:
  - **Material Palettes**: Extracted into dedicated material factories or resources (`CastleMaterials`).
  - **Geometry & Mesh Builders**: Isolated pure mesh/CSG construction without game state (`CastleMeshBuilder`).
  - **Prop Factories**: Entity assembly, collision setup, and lighting configuration (`CastlePropFactory`).
  - **Zone Planners**: Layout and room placement algorithms (`CastleZonePlanner`).
  - **Facade**: A lightweight top-level class (`CastleBuilder`) coordinating sub-modules and providing a clean, backwards-compatible public API.

### 4. Separation of Audio DSP / Generation from Playback
- Algorithmic sound generation (PCM byte calculation, waveform synthesis) must be separated into synthesizer classes (`HeroQuestAudioSynth`).
- Audio manager classes (`HeroQuestAudio`) must focus purely on player pooling, bus routing, attenuation, and playback triggers.

## Consequences

### Positive
- **High Cohesion & Clear Ownership**: Each script has a single, well-defined reason to change.
- **Extensibility**: Adding new interactive props or new castle zones requires zero changes to the player or existing rooms.
- **Testability**: Material caches, mesh builders, and sound generators can be instantiated and validated independently in unit tests.
- **Predictable AI Pair Programming**: Small, modular classes prevent AI context saturation and reduce merge conflicts.

### Negative / Trade-offs
- Increased number of files in the project.
- Slight indirection via component nodes or helper classes (negligible runtime impact in Godot).

## Compliance & Enforcement
- The rules defined in this ADR are linked directly into [AGENTS.md](../../AGENTS.md).
- Any proposed additions that push a GDScript file over the 400-line limit must include a decomposition plan.
