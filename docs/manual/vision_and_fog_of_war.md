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
- **Position Dirty Checking**: Zero CPU raycasting or texture uploads while the hero is stationary.



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
3. **[`HeroQuestFogRenderer`](../../scripts/hero_quest/vision/hero_quest_fog_renderer.gd)** & **[`fog_of_war.gdshader`](../../shaders/fog_of_war.gdshader)**:
   - Generates a dynamic 2D FoW texture (`R` = active sight, `G` = explored memory).
   - Renders a screen-space depth-reconstructing spatial post-processing shroud with bilinear smooth gradients.

---

## 5. Controls & Level Editor Integration

- **`[F]` Key**: Hotkey in Play Mode to toggle Fog of War on/off (instantly reveal all for testing or exploration overview).
- **`[TAB]` Key (Level Editor)**:
  - Opening the Level Editor automatically disables the Fog of War shroud and lights all rooms so the designer has complete visibility of the entire map.
  - Exiting the Level Editor seamlessly restores the Fog of War around the hero's position.
