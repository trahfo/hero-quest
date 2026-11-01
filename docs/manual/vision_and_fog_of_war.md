# Line of Sight, Exploration & Fog of War System

Hero Quest 3D features a dynamic **Line of Sight (LoS) and Fog of War Exploration Model** inspired by the classic *Hero Quest* board game and atmospheric isometric dungeon crawlers.

---

## 1. Core Visibility Hierarchy

The dungeon level is divided into three distinct visibility tiers based on the hero's exploration progress:

| Tier | State | Description | Visual Appearance |
| :--- | :--- | :--- | :--- |
| **0** | **`UNEXPLORED`** | Shrouded, undiscovered dungeon areas. Rooms behind closed doors or corridors yet unvisited. | Pitch black (`#030406`), 0% visibility. Room torches and lights are turned off to prevent light bleeding through walls. |
| **1** | **`EXPLORED`** | Dungeon memory. Geometry and architectural elements previously discovered by the hero. | Subdued ambient tint (~22% brightness, `#6b7a9e`), showing discovered walls, floor tiles, and room contours. |
| **2** | **`VISIBLE`** | Real-time direct Line of Sight. | 100% full illumination powered by the hero's lantern and active torches/lights. |

---

## 2. Atmospheric Sight Distances & Quadratic Gradual Falloff

### 2.1. Gradual Atmospheric Feathering (Quadratic Falloff)
To produce an intimate, atmospheric dungeon crawler feel without seeing overly far, the sight distance is focused and gentle:
- **Core Illumination ($0 \le d \le \text{core\_radius}$)**: Direct lantern/torch light ($1.0 \to 0.88$).
- **Soft Quadratic Penumbra ($\text{core\_radius} < d \le \text{max\_radius}$)**: Continuous quadratic ease-out decay $(1 - u)^2$, fading out gently across 3.8 to 4.8 tiles into darkness.

### 2.2. Tuned Sight Radii
- **Dark Rooms / Unlit Corridors**: **`5.2` tiles total** (`1.4` core tiles + `3.8` soft falloff tiles).
- **Torches & Active Light Sources**: **`7.8` tiles total** (`3.0` core tiles + `4.8` soft falloff tiles).

### 2.3. Differential Real-Time Performance
- **O(1) Differential Stamping**: Only touches the ~30 active cells that changed, completely eliminating full-texture clearing loops.
- **Cell Dirty Checking**: Vision is cell-based, so it is recomputed only when the hero enters a new grid cell (or on a door/fog/editor change) — never per frame, never for sub-tile movement.



---

## 3. Occlusion Dynamics & Door Sightlines

- **Solid Modular Walls & Windows**: All modular walls (`type == WALL` / `6`) and window walls block line of sight.
- **Pillars & Solid Props**: Blocking stone pillars and heavy barriers occlude vision rays passing behind them.
- **Interactive Doors**:
  - **Closed Doors**: Completely block sight rays from penetrating into adjacent rooms. The hero can see the closed door's front face, but the chamber beyond remains pitch black.
  - **Opening a Door**: As soon as a door is opened (via `[E]` or `[SPACE]`), its tile walkability updates, immediately allowing sight rays to flood into the room. If the room contains torches or braziers, the entire room instantly illuminates.

---

## 4. Architectural Implementation & Modularity

Following [ADR 0001](../adr/0001-gdscript-modularity-and-class-size-limits.md), the system is decomposed into three focused components:

1. **[`HeroQuestLosCalculator`](../../scripts/hero_quest/vision/hero_quest_los_calculator.gd)**:
   - Pure-computation static math engine for 2D discrete raycasting and multi-source light aggregation.
   - Includes diagonal corner occlusion prevention to prevent ray leaks through diagonal wall corners.
2. **[`HeroQuestVisionManager`](../../scripts/hero_quest/vision/hero_quest_vision_manager.gd)**:
   - State coordinator tracking `explored_cells` and `visible_cells`.
   - Discovers dungeon `OmniLight3D` nodes and listens to `HeroQuestDoor.door_state_changed`.
   - Manages dynamic light activation and triggers FoW updates.
   - Delegates light state to [`HeroQuestLightBudget`](../../scripts/hero_quest/vision/hero_quest_light_budget.gd).
3. **[`HeroQuestFogRenderer`](../../scripts/hero_quest/vision/hero_quest_fog_renderer.gd)** & **[`fog_of_war.gdshader`](../../shaders/fog_of_war.gdshader)**:
   - Generates a dynamic 2D FoW texture (`R` = active sight, `G` = explored memory), sized to the level's grid bounds with **1 texel per grid cell**; bilinear sampling feathers the cell borders.
   - Renders a screen-space depth-reconstructing spatial post-processing shroud with bilinear smooth gradients.

---

## 4b. Performance Budget

Measured on `first_level.json` (1624 tiles, ~8300 meshes, 86 omni lights), headless:

| Metric | Before | After |
| --- | --- | --- |
| Vision work while walking (200 frames) | ~447 ms | ~2.7 ms |
| Forced vision update | ~1.9 ms | ~0.18 ms |
| Fog texture stamping | 7x7 `get_pixel`/`set_pixel` per cell | 1 texel per cell, upload only when dirty |
| Shadow-casting lights lit at once | up to all visible torches | nearest 4 |
| Relief bricks in shadow passes | all (~2000 casters) | none |

Rules that keep it cheap (do not regress them):
1. **Recompute on cell change only** — `update_vision()` returns immediately while the hero stays in the same grid cell.
2. **FoV cache** — per-source FoV is cached by `(cell, radius, falloff)` in `_fov_cache` (`HeroQuestLosCalculator.compute_fov_cached`), and `is_cell_blocking` is memoised. Both caches are cleared by `invalidate_caches()` on door state changes and `refresh_scene_entities()` (editor/fog toggles). Anything that changes blocking cells must call it.
3. **Light range test first** — lights outside the hero's `dark_sight_radius + 1` box are never ray-traced.
4. **Shadow budget** — `HeroQuestLightBudget.apply_shadow_budget` keeps `shadow_enabled` only on the `MAX_SHADOW_LIGHTS` (4) nearest active lights.
5. **Idle lights are free** — hidden lights pause their flicker `Timer`; `visible` is only written when it actually changes.
6. **Small relief meshes never cast shadows** (`CastleBrickScatterer`).

Tests: `scripts/tests/test_suite_vision_performance.gd`.

---

## 5. Controls & Level Editor Integration

- **`[F]` Key**: Hotkey in Play Mode to toggle Fog of War on/off (instantly reveal all for testing or exploration overview).
- **`[TAB]` Key (Level Editor)**:
  - Opening the Level Editor automatically disables the Fog of War shroud and lights all rooms so the designer has complete visibility of the entire map.
  - Exiting the Level Editor seamlessly restores the Fog of War around the hero's position.
