# Hero Quest 3D: System Documentation & User Manual

Welcome to the Hero Quest 3D manual and system specification hub. This documentation provides comprehensive references for the level editor, gameplay mechanics, character systems, and architectural standards.

---

## Documentation Sections

### 1. [Level Editor Specification & User Guide](editor_guide.md)
Complete user guide and technical specification for the in-game 3D Level Editor:
- **Controls & Keybindings**: `TAB` quick-save & exit, `ESC` cancel/discard, Middle-Mouse pan, `R` rotate view.
- **3D Ghost Preview**: ~80% translucent holographic preview (`alpha <= 0.25`, unshaded, `render_priority = 3`) for all placeable objects.
- **Tools & Placement**: Floor rectangular drag, Wall line drag with auto-tiling, Arches with wall cutouts, Windows on straight runs, Chest designer, Wall-mounted smart snapping decors, and Room/Area blueprint mode.
- **Contextual Deletion & Persistence**: Two-stage right-click deletion, pre-save health validation, spawn auto-healing, and undo/redo history.

### 2. [Character Systems, Archetypes & Locomotion](character_systems.md)
Reference for player characters, visual morphology, and skeletal kinematics:
- **Class Archetypes**: Hot-swapping via number keys `[1]` Adventurer, `[2]` Knight, `[3]` Scout, `[4]` Arcanist.
- **Locomotion Kinematics**: Godot `-Z` forward conventions, cardinal facing formulas, and the strict **Anatomical Knee Flexion Law** (`Shin.rotation.x <= 0.0`).
- **Continuous Movement**: Multi-tile uniform velocity ("Walk Walk Walk as One") without halting at tile boundaries.
- **Isometric Input Rotation**: Camera-relative direction formula ensuring Arrow Down always moves toward the screen lower-left.

### 3. [Character Sheet, Inventory & Gameplay Systems](inventory_and_gameplay.md)
Guide for player progression, items, loot, and interaction systems:
- **Character Sheet (`C` Key)**: Attributes, dice values, equipment slots (Weapon, Armor, Shield, Relic).
- **Loot Dialogue & Item Database**: Common, Rare, Epic, and Legendary gear comparisons and chest interactions.
- **3D Dropped Floor Items**: Pedestal rings, hovering relic bobs, rarity beacon lights, and non-blocking pickup prompts.
- **Component Interaction Pattern**: `HeroQuestInteractable` architecture for uniform object interaction.
- **Start Menu & Level Browser**: Paginated level discovery and draft-safe level canvas generation.

### 4. [Line of Sight, Exploration & Fog of War](vision_and_fog_of_war.md)
Reference for dynamic Line of Sight, dungeon exploration memory, and lighting:
- **3-Tier Visibility**: `UNEXPLORED` pitch black, `EXPLORED` subdued dungeon memory, `VISIBLE` direct sightline illumination.
- **Light Amplification**: Torch and brazier sight boost (`8.0` tiles) over dark pitch-black rooms (`4.5` tiles).
- **Door Occlusion**: Closed doors block ray penetration; opening doors instantly reveals room interiors.
- **Controls & Editor**: `[F]` toggle Fog of War on/off, automatic full-visibility bypass in Level Editor (`[TAB]`).

### 5. [Tile & Prop Positioning Ruleset](../tile_positioning_ruleset.md)
The geometric and spatial reference for architectural builders and procedural systems:
- Standard metrics (`TILE_SIZE = 2.0m`, `WALL_THICKNESS = 0.9m`, `WALL_HEIGHT = 4.5m`).
- Modular wall arm connectivity and outer corner ashlar quoins.
- Arch spans (3-tile, 4-tile, cloister arcades) and door pier widening.
- Continuous stone floor substrate under all wall segments.
- Procedural PBR materials, mortar borders, and ashlar relief brick scattering.

---

## Agent Skills & Automation

For autonomous level creation and procedural design:
- **[`level-architect` Skill](../../.agents/skills/level-architect/SKILL.md)**: A dedicated agent skill that leverages these rulesets to prompt and build entire castle levels, generate interconnected rooms, and construct valid JSON level data.

