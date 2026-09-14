# Hero Quest 3D: Tile & Prop Positioning Ruleset

This document specifies the architectural, spatial, and geometric rules for tile placement, wall modeling, arch alignment, and prop orientation in the Hero Quest 3D castle project.

---

## 1. Grid Metrics & Dimensions

| Element | Metric | Value | Rationale |
| :--- | :--- | :--- | :--- |
| **Tile Size** | `TILE_SIZE` | `2.0m` | Standard grid cell width and length. |
| **Wall Thickness** | `WALL_THICKNESS` | `0.9m` | Matches column shaft width (`0.9m`) for seamless alignment. |
| **Wall Height** | `height` | `4.5m` | Standard exterior barrier and room height. |
| **Pier / Column Height** | `height` | `3.6m` | Springing height for all architectural arches. |
| **Grid to World Transform** | `world_pos` | `Vector3(gx * 2.0, 0, gz * 2.0)` | Center of cell `(gx, gz)`. |

---

## 2. Wall Thickness & Modular Wall Classification

Walls must **never** be solid `2.0m x 2.0m` cubic blocks. They must strictly have `WALL_THICKNESS = 0.9m`.

Every wall tile is constructed dynamically using `CastleWallTileFactory.create_modular_wall` based on its neighbor connections:

```
          [has_up (-Z)]
                |
[has_left (-X)]-+- [has_right (+X)]
                |
         [has_down (+Z)]
```

### Classification Types:
1. **Straight X-Wall** (`has_left and has_right and not (has_up or has_down)`):
   - Box size: `Vector3(TILE_SIZE, height, WALL_THICKNESS)` = `(2.0, 4.5, 0.9)`.
   - Used for North and South walls.
2. **Straight Z-Wall** (`has_up and has_down and not (has_left or has_right)`):
   - Box size: `Vector3(WALL_THICKNESS, height, TILE_SIZE)` = `(0.9, 4.5, 2.0)`.
   - Used for East and West walls.
3. **Corner L-Junction** (1 connection in X, 1 connection in Z):
   - Central `0.9m x 0.9m` column at `(0, 0)`.
   - Connecting X-arm (`0.55m x 0.9m`) and Z-arm (`0.9m x 0.55m`).
   - Exterior corner quoin ashlar blocks on the outer diagonal corner.
4. **T-Junction** (3 connections):
   - Central `0.9m x 0.9m` column + **all 3 connecting arms**.
   - Used where partition walls, corridors, or wings meet perimeter walls. Never omit the third arm.
5. **4-Way Cross Junction** (4 connections):
   - Central `0.9m x 0.9m` column + all 4 connecting arms.
6. **End Stub** (1 connection):
   - Central `0.9m x 0.9m` column + single connecting arm towards neighbor.

---

## 3. Perimeter Wall Discovery & Sealing Rules

### 3.1. Room Tile Filtering (No Gaps Behind Props)
- When scanning the grid to generate perimeter walls, **never** filter by `walkable == true`.
- Walkability is set to `false` when a cell is occupied by furniture (cupboards, drawers, bookshelves, hay bales, troughs, altars, or chests).
- Instead, filter by tile **type**:
  ```gdscript
  var type = info.get("type", 0)
  if type == 0 or type == 6 or type == 7: # Skip EMPTY, WALL, CHASM
      continue
  ```
- Every room cell generates perimeter walls on unassigned adjacent cells, regardless of prop occupancy.

### 3.2. Diagonal Neighborhood for Zig-Zag Walls
- In round towers, octagonal rooms, and stepped/zig-zag perimeters, orthogonal checks alone leave missing outer diagonal corners (1-tile holes).
- Perimeter wall collection **must inspect both orthogonal and diagonal neighbors**:
  ```gdscript
  var neighbor_offsets = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
  var diagonal_offsets = [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]
  ```
- Any unassigned neighbor (orthogonal or diagonal) bordering a room cell is registered as a perimeter wall tile.

---

## 4. Arches, Door Piers, and Column Alignments

### 4.1. Door Pier Widening (Single Unified Object)
- Column shafts (`0.9m x 0.9m`) are centered in a `2.0m` cell, leaving a `0.55m` gap to the cell boundary where adjacent walls meet.
- **Never instantiate separate attached wall meshes** next to a door column.
- Instead, the pier itself must expand directly along `extend_dir`:
  - Plinth base expands to `1.6m` along `extend_dir` (offset `0.2m`).
  - Column shaft expands from `0.9m` to `1.45m` (`0.9m + 0.55m`, offset `0.275m`).
  - Capital expands to `1.575m` (offset `0.2125m`).
- Produces a single, solid architectural pilaster/pier touching the adjoining wall seamlessly with zero extra child objects.

### 4.2. Mathematical Arch Span & Springing Height
The ends of curved arches must land directly on top of the column capitals (`y = 3.6m`), never float in mid-air:

| Arch Type | Pier Distance | Correct Span | Radius | Spring Height |
| :--- | :--- | :--- | :--- | :--- |
| **3-Tile Arch** (1 open doorway) | `±1` tile (`±2.0m`) | `4.0m` (`2.0 * TILE_SIZE`) | `2.0m` | `3.6m` |
| **4-Tile Arch** (2 open doorways) | `±1.5` tiles (`±3.0m`) | `6.0m` (`3.0 * TILE_SIZE`) | `3.0m` | `3.6m` |
| **5-Tile Twin Arch** (2 twin doorways) | `±1` tile per arch (`±2.0m`) | `4.0m` (`2.0 * TILE_SIZE`) | `2.0m` | `3.6m` |
| **Garden Cloister Arcade** | 3-tile pillar gap (`6.0m`) | `6.0m` (`3.0 * TILE_SIZE`) | `3.0m` | `3.6m` |

---

## 5. Corridors & Doorway Width Matching

- Corridor widths must **strictly match** the doorway or arch width passing through them.
- If a 4-tile arch (`[-2, 1]`) spans the corridor, the corridor floor must be **4 tiles wide** (`range(-2, 2)`, i.e. `gx ∈ [-2, 1]`).
- A 5-tile wide corridor with a 4-tile arch leaves an open gap beside the door pier. Always size connector corridors to match their portal arches.
- **Corridor Ingress Clearance**: Blocking props (hay bales, troughs, furniture) must never occupy the entry cells or alignment lanes of connector corridors (e.g. `gx = -12` from the Garden into the Royal Stables). Thoroughfares must remain unobstructed.

---

## 6. Windows: Placement & Construction

### 6.1. Dedicated Window Wall Tile
- Windows must **not** be floating meshes parented over solid walls.
- They must be dedicated `0.9m` thick wall tiles (`CastleWallTileFactory.create_window_wall`):
  - Left & Right jamb columns: `0.5m x 0.9m x 4.5m`.
  - Lower sill: `1.0m x 0.9m x 1.25m` with chamfered projecting windowsill shelf.
  - Upper lintel: `1.0m x 0.9m x 0.85m`.
  - **Embrasure Corner Reveals**: Angled/stepped stone reveals flanking the window opening, creating a recessed medieval window alcove.
  - Tracery frame, pointed arch top, stained glass, iron mullions, and omni light.

### 6.2. Elimination of Z-Fighting
- The top coping cornice must be a **single continuous box** spanning `TILE_SIZE` (`2.0m x 0.35m x 0.9m`).
- The stone lintel body must be positioned strictly **below** the cornice (`y = height * 0.5 - cornice_h - lintel_body_h * 0.5`).
- Co-planar overlapping boxes between different materials are strictly prohibited.

### 6.3. Window Positioning Constraints
1. **Never in Corners**: Windows must never be placed in corner tiles or adjacent to door piers.
2. **Straight Run Placement**: Windows must always be centered on straight wall sections.
3. **Mandatory Watchtower Windows**: Every watchtower must feature at least one lookout window facing outward.
4. **Chapel & Stables**: Stained glass windows should be placed on North, East, and West walls of chapels, and multiple exterior windows along stable walls.

---

## 7. Furniture, Rugs, and Props

### 7.1. Wall-Aligned Furniture Rotation
Blocking furniture with a flat back (cupboards, drawers, bookshelves, weapon racks) must rest flat against the wall:

| Wall Location | Wall Normal (Facing Room) | Furniture `rot_y` |
| :--- | :--- | :--- |
| **West Wall** | `+X` (East) | `PI * 0.5` (`+90°`) |
| **East Wall** | `-X` (West) | `-PI * 0.5` (`-90°`) |
| **North Wall** | `+Z` (South) | `0.0` (`0°`) |
| **South Wall** | `-Z` (North) | `PI` (`180°`) |

### 7.2. Rugs & Carpets
- Carpets are thin cloth rugs on stone floors, not raised platforms.
- Thickness: `size.y = 0.02m`.
- Position: `y = 0.01m` (resting flush on floor from `y = 0.00` to `y = 0.02`).

### 7.3. Character Tile Cursor Elevation
- The yellow tile cursor must sit above the floor and carpets:
  - Transform: `y = 0.035m` - `0.04m`.
  - Material: `render_priority = 2` with transparency.
  - Guarantees the cursor is always clearly visible on top of red carpets without z-fighting.

### 7.4. Tables and Chairs
- **Clearance from Carpets**: Tables must never step onto carpet borders. Keep at least 1 tile (`1.2m+`) clearance from carpet edges.
- **Chair Requirement**: **Every table in the game must have at least one chair or stool** (e.g. pulled up to the table or tucked into it).
- **Chair Facing Direction**: All chairs must be oriented towards their table:
  - Chair default local orientation (`rot_y = 0.0`) faces `-Z` with the backrest at `+Z`.
  - When placed on the `+Z` side of a table, set `rot_y = 0.0` so the chair faces `-Z` into the table.
  - When placed on the `-Z` side of a table, set `rot_y = PI` so the chair faces `+Z` into the table.
  - When placed on the `-X` (West) side of a table, set `rot_y = -PI * 0.5` so it faces `+X` into the table.
  - When placed on the `+X` (East) side of a table, set `rot_y = PI * 0.5` so it faces `-X` into the table.

### 7.5. Benches and Church Pews
- **Legs and Floor Grounding**: Benches and church pews must never be floating slabs in mid-air.
- **Church Pews (`is_pew == true`)**:
  - Must feature solid Gothic wooden end panels on both ends (`x = ±(length * 0.5 - 0.06)`) extending from floor level (`y = 0.0`) up to armrest height (`y = 0.85`).
  - For 2-tile or multi-tile pews (`length > 2.0m`), a center support leg must be placed at `x = 0.0` from `y = 0.0` to `y = 0.4`.
- **Wooden Benches (`is_pew == false`)**:
  - Must feature end support legs extending down to `y = 0.0` and a center leg for lengths exceeding 2.0m.

---

## 8. Wall Lamps & Torches

### 8.1. Wall Mounting Contact (Zero Floating)
- Torches and lanterns must be physically connected to the wall surface:
  - Base position on wall face: `wall_cell_pos + wall_normal * 0.45` (or from room cell: `room_cell_pos - wall_normal * 1.55`).
  - Never place wall lamps at an arbitrary `0.8m` from room center, which leaves a `0.75m` gap in empty air against `0.9m` modular walls.
- Brackets must extend outward along `wall_normal` into the room from the stone face.

### 8.2. Absolute Window Clearance (Torches NEVER on Windows)
- **Torches may NEVER come out of windows or be placed on window tiles**.
- Wall lamps must only be mounted on solid wall piers, columns, or between window embrasures.
- Always check the wall tile coordinate against `window_spots`. If a tile has an exterior window (such as `Vector2i(-16, 0)` in the stables), mount torches on adjacent solid wall piers (e.g. `gz = -1` and `gz = 1`).

---

## 9. Procedural Ashlar Brick Scattering & Z-Fighting Elimination

### 9.1. Permanent Elimination of Co-Planar Flickering
- Bricks must **never** be co-planar with any face of the wall (`z = ±0.45` or `x = ±0.45`).
- Outward normals must be explicit: Front `(0, 0, 1)`, Back `(0, 0, -1)`, Right `(1, 0, 0)`, Left `(-1, 0, 0)`.
- Every relief block must embed `0.025m` inside the wall and protrude outward:
  - Position: `center + u_axis * u + Vector3.UP * v + norm * (depth * 0.5 - 0.025)`.
  - For `depth = 0.06m`, back face is at `wall - 0.025m` (inside stone), front face is at `wall + 0.035m` (in air).
  - Guarantees zero z-fighting on all GPUs now and forever.

### 9.2. Non-Overlap Rejection Sampling
- 2D rejection sampling using `Rect2` bounding boxes with a minimum clearance padding of `0.08m` ensures stones **never overlap**.
- Dimension variation: width `0.32m - 0.58m`, height `0.20m - 0.30m`, depth `0.06m - 0.08m`.
- Relief blocks are strictly contained between the base plinth and top cornice (`y = [-1.7m, +1.8m]`).
- Deterministic pseudo-random seeding based on tile grid coordinate and surface normal ensures repeatability without frame jitter.

---

## 10. Gardens, Plazas, and Path Networks

- **Cloister Gardens**:
  - Feature non-green stone floor tiles (`materials.mat_floor_stone`) for straight paths and central plazas.
  - Straight paths run along primary axes connecting gateways, portals, and watchtower doors.
  - Central plazas provide ample space (e.g. 4x4 tiles) housing focal multi-tile centerpieces like fountains, framed by arcade pillars and arches.
  - Lawn quadrants utilize lush green tiles (`materials.mat_floor_garden_green`) accented with bushes and flower patches.

---

## 11. Courtyard Chasm Balustrades & Fences

- Open courtyards bordering chasm/abyss tiles (`type == 7`) must have protective fences or balustrades along the cliff edge.
- Courtyard fences feature stone base curbs, stone end posts, top/bottom handrails, and vertical iron pickets with colliders.
- **Clearance from Bridge Railings & Arch Piers**: Fences must never overlap bridge railings or arch piers located at `gx = ±2`. Fences are shortened by 1 tile (length `10.0m = 5 tiles`) covering `gx: -7..-3` (centered at `x = -10.0m`) and `gx: 3..7` (centered at `x = +10.0m`), keeping `gx = ±2` completely unencumbered.

---

## 12. Camera Rotation Controls

- **Clockwise 90° View Rotation**:
  - Pressing the `R` key decrements `target_cam_yaw` by `90.0°`.
  - Camera pivot smoothly interpolates towards target yaw via `lerp_angle(deg_to_rad(current), deg_to_rad(target), 10.0 * delta)`.

---

## 13. Inter-Room Windows Prohibited

- **Rule**: Windows between indoor rooms are **strictly forbidden**.
- Partition walls separating two indoor rooms (e.g. wall between Grand Chapel and Grand Dining Hall along `gx = 7`) must consist purely of solid stone modular wall tiles.
- **Outdoor / Garden Exception**: Cloister gardens and courtyards count as outdoor spaces; walls separating an indoor room from a garden (e.g. west wall of Grand Chapel along `gx = -7`) may contain gothic stained glass windows. Exterior castle walls facing the open wilderness or chasm abyss may also contain windows.

---

## 14. Wall Separation Distance Rule

- **Rule**: There must **always be at least one tile between separate walls**.
- Parallel walls of adjacent rooms or structures must never sit back-to-back on adjacent tiles (which produces two touching wall rows with zero clearance).
- Example: The south wall of the Cloister Garden (`gz = -9`) and the north wall of the Royal Stables (`gz = -7`) are separated by at least one full tile row (`gz = -8`), which serves as a connecting corridor or open courtyard space.

---

## 15. Corridor Door Matching Rule

- **Rule**: When a corridor exits one room through a door or arch, the other room where the corridor leads to **must also have a door or arch**, and never just a bare hole in the wall.
- Both the entrance and exit of connector corridors must be framed with matching architectural portals:
  - *Dining-to-Forge Corridor*: Exits Dining Hall through `Dining Forge Gate` (`Vector2i(12, -8)`) and enters Blacksmith Forge through `Forge Dining Gate` (`Vector2i(12, -7)`).
  - *Garden-to-Stables Corridor*: Exits Cloister Garden through `Garden Stables Gate` (`Vector2i(-12, -9)`) and enters Royal Stables through `Stables Garden Gate` (`Vector2i(-12, -7)`).
  - *Great Corridor to Stables/Smith*: Framed on both sides (`West Portal` / `Stables Gate` and `East Portal` / `Forge Gate`).

---

## 16. Half-Height Bridge Railings & High Wall Prohibition

- **Rule**: Never generate large (4.5m) walls over half-height walls.
- Bridge walkway tiles (`type == 4`, FLOOR_BRIDGE) are explicitly excluded from full-height perimeter wall generation.
- Courtyard tiles (`type == 5`, FLOOR_COURTYARD) generate solid 4.5m perimeter walls bordering unassigned empty space on the South (`gz = 19`), East (`gx = 8`), and West (`gx = -8`), but are excluded from generating 4.5m walls bordering the northern chasm abyss (`gz = 12`) where protective iron balustrades reside.
- The chasm bridge features dedicated half-height (`1.8m`) stone balustrade railings (`BridgeRailLeft` and `BridgeRailRight` along `gx = ±2`, `gz: 7..12`), providing clear visual sightlines down into the chasm abyss.

---

## 17. Bridge 3-Field Arches at Start and End Only

- **Rule**: The chasm bridge features monumental triumphal arches spanning across the 3-field wide walkway (`gx: -1..1`) **at the start and at the end only**.
- There is **no arch in the middle of the bridge**.
- Arches are placed strictly at:
  - **Bridge Start** (`gz = 6`): `Bridge North Arch` spanning across `gx: -1..1` with piers at `gx = ±2`.
  - **Bridge End** (`gz = 13`): `Courtyard Portal` spanning across `gx: -1..1` with piers at `gx = ±2`.
- Mathematical span is `8.0m` (`4.0 * TILE_SIZE`), with piers seated squarely on top of the bridge railing lines at `gx = -2` and `gx = +2`.
- Spring height is `3.6m`, allowing unobstructed character passage through the center doorway.

---

## 18. No Windows in Doors or Arches

- **Rule**: Windows may **never be placed in cells containing doors, portals, or arches**.
- Every door/arch opening must be framed by solid stone piers, lintels, and voussoirs with zero overlapping window embrasures, tracery, or glass.
- Windows must be offset along the wall to adjacent solid wall sections (e.g. Cloister Garden-facing Chapel window placed at `Vector2i(-7, -16)` away from `Garden Chapel Portal` at `Vector2i(-7, -14)`).

---

## 19. Watchtower Entrance Portals

- **Rule**: Every round watchtower must feature a dedicated stone portal arch at its entrance threshold.
- The North-West Watchtower entrance threshold (`Vector2i(-16, -15)`) from the Cloister Garden connector is framed with a 3-tile arch (`NorthWestTowerPortal`) with piers embedded in the tower perimeter ring.

---

## 20. Corridor Width & Portal Proportion Scaling

- **Rule**: Connector corridor widths must expand to match multi-lane thoroughfares and arch spans.
- **Garden-to-Stables Corridor**: 3 tiles wide (`gx: -13..-11`), framed by 3-field spanning arches at both the garden exit (`gz = -9`) and stable entrance (`gz = -7`).
- **North Passage**: 5 tiles wide (`gx: -2..2`), centered symmetrically on the Great Hall red carpet axis (`gx = 0`) and framed by a 3-field spanning arch (`Hall North Arch`) at `gz = -7`.

---

## 21. Graveyard Zoning, Cemetery Fencing, and Outdoor Stake Torches

- **Location & Access**:
  - The Graveyard is located directly behind (North of) the Cloister Garden spanning `gx: -16..-8` and `gz: -33..-26` (9 columns x 8 rows).
  - Entrance from the Cloister Garden is along the central north-south garden path (`gx = -12`) through a dedicated 3-tile portal arch at `Vector2i(-12, -25)`.
  - The threshold cell `Vector2i(-12, -25)` must never contain exterior windows, maintaining solid flanking wall piers at `(-13, -25)` and `(-11, -25)`.
- **Cemetery Perimeter Fencing vs. Castle Walls**:
  - Open-air cemetery grounds (`FLOOR_GRAVEYARD`, `type = 8`) are bounded by dedicated wrought-iron fencing and stone corner/gate posts (`height = 1.3m`) rather than 4.5m solid stone castle perimeter walls.
  - The fence surrounds the outer cemetery perimeter with continuous collision bounds, leaving an open gate at the central path (`gx = -12`).
- **Gravestone Clearance & Interactivity**:
  - Gravestones are placed squarely on grid cells with `walkable = false` and attach `HeroQuestInteractable` components with inspectable epitaphs.
  - Clear 2-meter walkways must be maintained along the central axial path (`gx = -12`) and cross-paths between gravestone plots.
- **Outdoor Torches on Stakes**:
  - Torches on sticks must consist of a wooden ground stake driven into the earth (`height = 1.8m`), an iron mounting cradle, glowing flame geometry, and dynamic flickering omni lights (`light_energy ~1.8`, `omni_range ~8.0m`).
---

## 22. Text-Based Level Data Structure & Side-by-Side World Loader

- **Separation of World Definition from Procedural Planners**:
  - The entire medieval fortress (1,444 tiles, 12 distinct rooms/wings, all props, arches, lighting, and interactables) is represented by a structured JSON data file (`res://data/levels/first_level.json`).
  - The level file defines rooms, tiles (`[x, z]`, tile type, walkability, zone name, floor material), architectural arches, perimeter walls, furniture, lights, and interactables.
- **Side-by-Side Coexistence**:
  - `CastleBuilder` supports both `BuildMode.ORIGINAL_PROGRAMMATIC` (generating dynamically via GDScript procedural algorithms) and `BuildMode.LEVEL_FILE` (reading and instantiating directly from JSON).
  - The loader (`CastleLevelReader` & `CastleLevelPropSpawner`) independently reconstructs the exact node tree, collision bounds, and metadata so that all gameplay systems and tests run identically regardless of which mode is selected.
- **Level Start Selection**:
  - At game launch, the player is presented with a choice between the original procedural level and the level loaded from the text-based file via a dedicated UI modal (`LevelSelectModal`).

---

## 23. Solid Floor Tiles Under Walls & Arch/Door Clearance Constraints

### 23.1. Continuous Stone Floor Substrate Under All Wall Tiles
- **Rule**: Every perimeter wall tile and arch pier must have a solid stone floor tile (`materials.mat_floor_stone`) instantiated directly beneath it (`y = 0.0m`, thickness `0.28m`).
- Modular walls (`0.9m` thickness) and window walls occupy standard `2.0m x 2.0m` grid cells. Without floor meshes underneath, the remaining `0.55m` margins float over empty void/skybox.
- Floor instantiation must track generated cells to guarantee 100% coverage with zero duplicate overlapping floor meshes.

### 23.2. Arch & Door Opening Clearance (Prohibition of Wall Arm Intrusions)
- **Rule**: Modular wall arms must **never extend into walkable cells, door frames, or arch passage openings**.
- Neighbor connectivity checks (`has_left`, `has_right`, `has_up`, `has_down`) must evaluate neighbor cells as:
  - If neighbor is a walkable corridor, passage, or room tile (`walkable == true`), the arm connection towards that direction must strictly be `false`.
  - Arch piers (`type == 6`, zone containing "Pier") count as valid wall connection targets, allowing modular walls to meet arch column shafts flush at tile boundaries without protruding beyond them.
- Straight walls bordering multi-pier gateways (e.g. Garden-Stables corridor gates along `gx = -14` and `gx = -10`) must orient along the pier axis (Z-axis straight walls) rather than defaulting to orthogonal X-axis walls that extend arms into the walkway.

### 23.3. Half-Height Bridge Railing Clearance
- Bridge railing corridors along `gx = ±2`, `gz: 7..12` house dedicated `1.8m` balustrade rails (`BridgeRailLeft` and `BridgeRailRight`).
- Diagonal neighbor sweeps must explicitly exclude the bridge railing corridor from generating full-height `4.5m` perimeter walls over the half-height rails or colliding with bridge arch piers at `(±2, 6)`.

### 23.4. Tower Entrance Arch Pier Window Clearance
- Windows may never be placed on cells designated as arch piers or doorway thresholds.
- The window on the North-West Watchtower perimeter is placed on solid wall cell `Vector2i(-16, -13)` with outward normal `Vector3(1, 0, 0)` into the Cloister Garden, maintaining complete clearance from `NorthWestTowerPortal` pier at `Vector2i(-16, -14)`.

---

## 24. 3D Dropped Floor Item Positioning & Clearance

### 24.1. Elevation & Substrate Clearance
- **Height Offset**: Dropped items (`HeroQuestFloorItem`) must be instantiated at base elevation `y = 0.15m`.
  - Pedestal ring: `y = 0.03m` (`height = 0.06m`) resting flush on the stone floor without clipping into tile geometry.
  - Hovering relic / crystal: Animated sine-bobbing at `y = 0.35m` to `y = 0.41m` with continuous slow Y-rotation.
  - Beacon light: `OmniLight3D` elevated at `y = 0.45m` with radius `2.5m` and energy `0.6`, color-coded to item rarity.

### 24.2. Spatial Placement & Ejection Clearance
- When dropped or ejected via equipment switching (e.g. equipping a new weapon over an occupied slot):
  - Position centers squarely on the player's current tile or the chest's interaction threshold.
  - Interactive component `HeroQuestInteractable` is set to `InteractType.ITEM` with prompt text `Press [E] or [SPACE] to pick up [Item Name]`.
  - Non-blocking footprint: Hero can step directly into proximity or face the item from any adjacent tile to trigger the inspection and loot dialogue.

---

## 25. Level Editor Interaction & Placement Constraints

### 25.1. Dotted Grid Overlay & View Alignment
- **Rule**: In edit mode, the editor grid must remain continuously visible across the active area as subtle dotted lines.
- **Elevation**: Dotted grid is rendered at `y = 0.02m` above the stone floor substrate with depth testing and transparency to prevent GPU z-fighting.
- **Pattern**: Dashed / dotted line frequency aligns to `TILE_SIZE` (2.0m) boundaries, clearly delineating integer coordinates `Vector2i(gx, gz)`.

### 25.2. Drag-to-Place Interactions
- **Rectangular Floor Drag**: Holding left-click and dragging defines a 2D bounding span `[min_x..max_x, min_z..max_z]`. On release, fills all encompassed cells with the active floor material.
- **Line Wall Drag**: Holding left-click and dragging defines a line constrained to the dominant orthogonal axis (X or Z). On release, places walls along that line.

### 25.3. Wall Auto-Tiling & Connectivity Rules
- Placed walls dynamically inspect their 4 orthogonal neighbors (`has_left`, `has_right`, `has_up`, `has_down`).
- Automatically resolves Straight X (`(2.0, 4.5, 0.9)`), Straight Z (`(0.9, 4.5, 2.0)`), L-corner, T-junction, 4-way cross, or end-stub geometry via `CastleWallTileFactory.create_modular_wall`.
- When a wall is placed or deleted, connectivity for all adjacent wall neighbors must be recalculated and refreshed.

### 25.4. Window Placement Constraints
- **Corner Window Prohibition**: Windows may **never** be placed in corner wall tiles (any tile with connections along both X and Z axes) or end stubs.
- **Arch / Doorway Clearance**: Windows may **never** be placed on cells containing portals, arches, or door piers.
- If a wall segment containing a window is altered such that it turns into a corner or intersects a door, the window must be rejected or replaced with solid wall.

### 25.5. Chest Designer & Placement
- Custom chests can specify relic/item name, gold bounty, trap status, and 4-way cardinal facing rotation (`0°`, `90°`, `180°`, `270°`).
- Chests occupy `1.0` tile with `walkable = false` and attach `HeroQuestInteractable` components with type `CHEST`.

### 25.6. Level Persistence & Undo History
- Pressing the `Tab` key toggles the level editor and automatically saves the updated world to `res://data/levels/first_level.json`.
- The editor session maintains an undo stack with a minimum capacity of 30 steps (default: 50 steps), capturing previous and modified cell, wall, and prop configurations.

---

## 26. Level Editor 3D Preview, Contextual Deletion, Batching & Intelligent Snapping

### 26.1. 80% Holographic Ghost Preview
- In edit mode, a semi-transparent preview of the currently selected tool/item must follow the mouse raycast in real-time.
- Preview nodes clone the visual meshes, strip collision shapes, disable light sources, and apply a holographic unshaded material with `alpha = 0.22` (approx. 80% transparency), `cull_mode = CULL_DISABLED`, and `render_priority = 3`.
- Windows and arches display their actual cutouts, gothic tracery, and stone piers rather than plain bounding boxes.

### 26.2. Contextual Two-Stage Right-Click Deletion
- **Stage 1 (Object First)**: If a prop, wall, chest, or arch exists at the hovered cell, right-clicking erases that object, restores the underlying floor tile's walkability, and preserves the floor mesh.
- **Stage 2 (Floor Second)**: Only if no object exists on the tile does right-clicking delete the floor tile itself.
- Camera panning is reassigned to **middle-mouse drag** (and WASD keys) to keep right-click completely unhindered for deletion.

### 26.3. Gap-Free Wall Line Batching
- Dragging wall lines must pre-register all cells along the line into the model's grid in batch before evaluating connectivity.
- After batch registration, `get_affected_neighborhood()` collects all line cells and their adjacent wall neighbors, refreshing auto-tiling across the entire set. This completely eliminates end-stub gaps and missing wall arms along dragged runs.

### 26.4. Intelligent Wall Deco Snapping & Elevation
- Wall-mounted decorations (torches, framed paintings) must automatically detect adjacent wall faces:
  - If placed on a wall cell, the normal points toward the open floor neighbor.
  - If placed on a floor cell adjacent to a wall, the decoration snaps flush to the wall face at `offset = 0.46m` from the wall center with normal pointing into the room.
  - **Mounting Elevations**: Wall torches mount at eye-level `y = 2.2m`; framed paintings mount at `y = 2.0m`.
  - Zero floor-level placement or perpendicular 90° jutting into the wall.

### 26.5. Same-Spot Hover Preview & Placement Rotation
- When hovering over an empty cell, the 80% ghost preview strictly displays the currently selected base orientation (e.g. West-East axis for arches). It must not auto-rotate upon initial placement.
- When hovering over a cell containing an existing object of the same type, the ghost preview in real-time shows the object rotated by 90° clockwise (`rot_y = fmod(rot_y + PI * 0.5, TAU)`), next cardinal wall face for wall decors, or toggled span axis (`(axis + 1) % 2`) for arches/doors.
- When clicked, this previewed rotated ghost is placed at that exact orientation, ensuring a 100% WYSIWYG placement workflow.

### 26.6. Wall Cutout for Doors and Portals
- Placing an arch or portal onto an existing wall cell automatically clears the solid wall mesh from the doorway cell, ensuring a clean walkable threshold flanked by arch piers.

### 26.7. Physics Raycasting & Spatial Wall Deletion
- Contextual right-click deletion utilizes 3D physics raycasting (`DirectSpaceState3D.intersect_ray`) with normal-offset sampling (`hit_pos - hit_norm * 0.15`) to accurately hit 4.5m tall wall colliders without ray-penetration to background floor tiles.
- Wall deletion cleanses both custom editor walls and procedural base castle room spatial nodes (`_find_and_free_spatial_nodes`), converts the erased wall tile to walkable stone floor, and triggers auto-tiling updates for adjacent wall segments.
- **Editor Node Decoupling & Container Protection**: Editor subsystem nodes (`LevelEditorGrid`, `LevelEditorGhostPreview`, cursor meshes) must remain completely decoupled from the castle world hierarchy (`builder`), and spatial deletion queries must never `queue_free()` room containers or editor nodes. All floor nodes are recognized via elevation checks (`_is_floor_node`) to keep floor substrates intact.

### 26.8. Keyboard Shortcuts & Vertical Category Navigation
- **Vertical Categories**: Editor categories are displayed as vertical tab buttons on the left column, eliminating horizontal tab header scrolling.
- **ESC Key Behavior**: If an item/tool is selected for placement, `ESC` deselects the item, clears active button highlighting, and hides the 3D ghost preview. If no item is selected, `ESC` exits the editor without saving (discarding session edits).
- **TAB Key Behavior**: `TAB` saves the level to JSON and toggles out of the editor. All editor UI buttons have `focus_mode = FOCUS_NONE` and `_input(event)` intercepts `KEY_TAB` and `KEY_ESCAPE` before Godot GUI focus consumption.

---

## 27. Humanoid Character Modeling, Proportions, Facing Direction & Locomotion

### 27.1. Forward Coordinate Convention (-Z Forward)
- Character visual models strictly face **`-Z`** (Godot standard forward direction) in their rest pose.
- Nose, eyes, chest emblem, and boot toes must point along `-Z`.
- Cardinal facing rotation angles around the Y-axis:
  - **North** (`dir = Vector2i(0, -1)`, `Vector3(0, 0, -1)`): `angle = 0.0 rad` (`0°`).
  - **South** (`dir = Vector2i(0, 1)`, `Vector3(0, 0, 1)`): `angle = PI rad` (`180°`).
  - **East** (`dir = Vector2i(1, 0)`, `Vector3(1, 0, 0)`): `angle = -PI * 0.5 rad` (`-90°`).
  - **West** (`dir = Vector2i(-1, 0)`, `Vector3(-1, 0, 0)`): `angle = PI * 0.5 rad` (`+90°`).
- Exact mathematical formula: `target_angle = atan2(-dir.x, -dir.y)`.
- Directional turning is smoothly interpolated via `lerp_angle(visuals.rotation.y, target_angle, 16.0 * delta)`.

### 27.2. Vertical Ground Grounding & Collision Alignment
- Humanoid visual feet rest flush on the floor substrate at `y = 0.0m`.
- The character body uses a `CapsuleShape3D` (`radius = 0.42m`, `height = 1.8m`) centered at `y = 0.9m`.
- The yellow tile cursor remains elevated at `y = 0.035m` (`render_priority = 2`) above floor carpets.
- Lantern light is elevated to chest/head height at `y = 1.4m` (`energy = 1.1`, `range = 7.0m`).

### 27.3. Biomechanical Locomotion Walk Cycle & Anatomical Kinematics Law
- **Godot Coordinate Conventions (Facing -Z)**:
  - For bones hanging downward along `-Y` (thighs, shins, arms):
    - `rotation.x > 0` rotates the distal end **forward** towards `-Z`.
    - `rotation.x < 0` rotates the distal end **backward** towards `+Z`.
- **Strict Anatomical Knee Flexion Law**:
  - Human knees can **ONLY** bend backward (posterior flexion, folding the shin towards the hamstrings/buttocks). Human knees NEVER bend forward.
  - In Godot, shin rotation around X must **STRICTLY SATISFY `Shin.rotation.x <= 0.0` AT ALL TIMES**.
  - Peak knee flexion during mid-swing reaches `-0.96 rad` (`-55°` backward).
  - Near heel strike and mid-stance, the knee extends to `-0.04 rad` to `-0.06 rad` (nearly straight, reaching forward).
  - Any positive rotation (`Shin.rotation.x > 0`) is an anatomical violation (bending forward like a broken joint / flamingo) and is strictly forbidden.
- **Thigh & Hip Flexion**:
  - Forward swing: `Leg.rotation.x > 0` (peaks at `+0.44 rad` / `+25°` at heel strike).
  - Backward extension / push-off: `Leg.rotation.x < 0` (peaks at `-0.24 rad` / `-14°` trailing).
- **Foot & Ankle Roll**:
  - Dorsiflexion (toes up, heel lands first): `Foot.rotation.x > 0` (`+0.18 rad`).
  - Plantarflexion (heel rises, pushing off toes): `Foot.rotation.x < 0` (`-0.16 rad`).
  - Flat contact: `Foot.rotation.x = 0.0 rad` to `-0.02 rad`.
- **Contralateral Arm Counter-Swing**:
  - Arms swing opposite to legs: when Left Leg swings forward (`Leg_L.rotation.x > 0`), Left Arm swings backward (`Arm_L.rotation.x < 0`, `-0.32 rad`) and Right Arm swings forward (`Arm_R.rotation.x > 0`, `+0.32 rad`).
  - Elbows flex forward (`Forearm.rotation.x >= 0`, `+0.12 rad` to `+0.36 rad`).
- **Pelvis & Ground Clearance**:
  - Pelvis height remains at `y >= 1.025m` (bobs up to `1.050m` during mid-stance).
  - Boot sole elevation stays `>= 0.018m` during flight and rests flush at `y = 0.02m` above floor tiles, perfectly clearing carpets and floor trim.
- Animation playback speed synchronizes with grid travel velocity: `speed_ratio = 0.8 / (step_duration * 2.0)`.

### 27.4. Modular Morphology & Archetype Derivation
- All humanoid characters share the same modular joint hierarchy (`Root/Hips/Chest/...`).
- Appearance morphing manipulates dedicated visual container nodes, leaving bone joint transforms intact for uninterrupted animation playback.
- Supported parametric variations:
  - `head_scale`: Vector3 scaling on the head joint.
  - `head_shape`: "oval", "chiseled", "square", "round".
  - `hair_style`: "short_parted", "helmet", "ponytail", "long_wizard", "bald" with variable length and color.
  - `facial_hair`: "none", "goatee", "full_beard".
  - `torso_scale`: Chest width, height, and depth.
  - `arm_thickness` and `leg_thickness`: Muscle bulk scaling.
  - Predefined archetypes hot-swapped via keys: `[1] Adventurer Hero`, `[2] Heavy Iron Knight`, `[3] Elven Scout / Ranger`, `[4] Grand Arcanist / Wizard`.
- No intrusive full-screen or center-screen overlay banners during archetype switching.

### 27.5. Seamless Continuous Multi-Tile Locomotion ("Walk Walk Walk as One")
- When holding a movement key across multiple tiles in the same direction:
  - Movement speed across tile boundaries is strictly uniform and continuous ($\mathbf{v} = \Delta \mathbf{x} / \text{step\_duration}$).
  - Overshoot time fraction (`move_progress -= 1.0`) is preserved without losing delta or frames.
  - The character never drops to zero velocity or resets the walk cycle at intermediate tile boundaries.
  - Deceleration easing (`interp_t = sin(t * PI * 0.5)`) and smooth cross-fade to idle occur only on the final destination tile when input is released or obstructed.

### 27.6. Human Facial Proportions & Anatomical Leg Standards
- **Facial Architecture**:
  - Head model must include distinct anatomical regions: upper cranium, defined jaw/chin mandible, protruding nose bridge & tip, orbital brow ridge, recessed eye sockets with white sclera and colored irises/pupils, mouth line, and lateral ears.
  - Eyes must sit at 50% head height (rule of halves) recessed under the brow, avoiding flat box eyes on a sphere.
- **Leg & Foot Anatomy**:
  - **Thighs**: Tapered cylinders with front quadricep curvature and defined rounded kneecap (patella) joints at the lower knee pivot.
  - **Lower Legs**: Tapered shins with posterior calf muscle volume and boot cuffs.
  - **Feet**: Contoured boot geometry with heel block, arched instep, and tapered toe box extending forward into `-Z`.
  - **Knee Flexion**: High knee lift (`~0.88 rad` / `50°`) during the flight/swing phase for natural ground clearance, followed by forward knee extension into heel strike.

---

## 28. Level Architecture, File Persistence & Start Screen Browser

- **File-Driven Level Architecture**:
  - All procedural room planners are fully deprecated. All castle worlds and custom levels are read exclusively from JSON level files via `CastleLevelReader` and saved via `LevelEditorModel`.
  - Canonical level file `res://data/levels/first_level.json` contains all 12 rooms and 1444 tiles with zero hardcoded GDScript room generators.
- **Start Screen Level Browser & Pagination**:
  - Available levels are discovered from `res://data/levels/` with `first_level.json` pinned at the top.
  - The home screen lists up to **5 levels per page**.
  - Page navigation arrows (`◀ Prev` and `Next ▶`) cycle through pages, disabling at boundary conditions (`page == 0` or `page == total_pages - 1`).
  - Clicking any level button immediately starts gameplay in that level.
- **New Level Creation & Save-Gated Persistence**:
  - Clicking `➕ CREATE NEW LEVEL` prompts for a level name and launches the game directly in **Level Editor mode** (`start_in_edit_mode = true`).
  - New levels initialize with a clean 5x5 stone floor canvas centered at `(0, 0)` so the player has safe footing.
  - The level file is written to disk (`res://data/levels/<slug>.json`) **only when the user saves** (via `Save Level` button or `TAB` toggle).
  - Unsaved levels are never committed to disk, preserving a clean start screen level list.

---

## 29. Room & Area Management, Blueprint Mode & Level Renaming

### 29.1. Walls-Only Blueprint Mode Heuristics
- When the Room / Area tool is activated in the level editor, all non-wall elements must be cleanly hidden to expose the castle floorplan as an unobstructed architectural blueprint.
- **Node Classification Heuristics**:
  - **Kept Visible (Walls & Portals)**:
    - Any node whose name contains `"wall"`, `"tower"`, `"arch"`, `"portal"`, `"gate"`, `"pier"`, or `"window"`.
    - Any `StaticBody3D` having a child `CollisionShape3D` with `BoxShape3D.size.y >= 2.0m`.
  - **Hidden (Interior Elements)**:
    - Floor meshes (`MeshInstance3D` with size `(2.0, 0.28, 2.0)` at `y = -0.14`).
    - Interior props, furniture, pews, altars, cupboards, tables, and chairs.
    - Decors, carpets, bushes, trees, braziers, and cemetery props.
    - Interactive treasure chests.
    - OmniLights and torches.
- **Reversible Restoration**: All hidden nodes are recorded in a temporary collection and their visibility is restored when exiting the Room tool or switching to another tool.

### 29.2. Translucent Room Overlays & Visual Zoning
- Designated room cells render a flat, unshaded translucent box mesh (`size = Vector3(1.9, 0.02, 1.9)`) at `y = 0.025m`.
- **Overlay Metrics & Parameters**:
  - Elevation: `y = 0.025m` (sits cleanly above floor slabs and ground without z-fighting).
  - Margins: `0.05m` margin per side (`1.9m` box on `2.0m` grid) to keep underlying grid lines clearly visible.
  - Material: `StandardMaterial3D` with `shading_mode = SHADING_MODE_UNSHADED`, `transparency = TRANSPARENCY_ALPHA`, `albedo_color.a = 0.45`.
  - Color Palette: 10 harmonious hues (Royal Blue, Emerald Green, Crimson Red, Amethyst Purple, Amber Gold, Teal Cyan, Coral Orange, Rose Pink, Indigo, Lime).

### 29.3. Room Zone Persistence & Gameplay Integration
- Room names are assigned to tiles via `builder.grid[cell]["zone"]`, `cell_data[cell]["tile"]["zone"]`, and `current_level_data["rooms"]`.
- Level names are editable via `model.set_level_name(name)` and persisted under `"name"` in level JSON files.
- In gameplay, `castle_builder.get_zone_at_position(player.global_position)` reads `builder.grid[cell]["zone"]` and displays the room name banner on the player HUD.

---

## 30. Camera-Relative Arrow Input Rotation for Isometric Views

- **Screen-Space Direction Consistency**:
  - In fixed or rotatable isometric perspectives, directional keyboard input (Arrow Keys and WASD) must strictly track the camera's current viewing angle.
  - **Arrow Down / S Constraint**: Arrow Down must **always move the character towards the lower-left corner** of the screen regardless of camera rotation.
- **Rotation Quadrant Mapping**:
  - Base camera angle: `yaw = 45.0°` (looking from `(+X, +Z)` towards origin).
  - Each press of the `R` key rotates the camera clockwise by 90° (`yaw -= 90.0°`).
  - Input rotation formula:
    ```gdscript
    var k = posmod(roundi((45.0 - cam_yaw) / 90.0), 4)
    match k:
        1: return Vector2i(-dir.y, dir.x)
        2: return Vector2i(-dir.x, -dir.y)
        3: return Vector2i(dir.y, -dir.x)
        _: return dir
    ```
  - Resulting mappings per 90° rotation:
    - `k = 0` (`yaw = 45°`): Down $\to$ South `(0, 1)`, Right $\to$ East `(1, 0)`, Up $\to$ North `(0, -1)`, Left $\to$ West `(-1, 0)`.
    - `k = 1` (`yaw = -45°`): Down $\to$ West `(-1, 0)`, Right $\to$ South `(0, 1)`, Up $\to$ East `(1, 0)`, Left $\to$ North `(0, -1)`.
    - `k = 2` (`yaw = -135°`): Down $\to$ North `(0, -1)`, Right $\to$ West `(-1, 0)`, Up $\to$ South `(0, 1)`, Left $\to$ East `(1, 0)`.
    - `k = 3` (`yaw = -225°`): Down $\to$ East `(1, 0)`, Right $\to$ North `(0, -1)`, Up $\to$ West `(-1, 0)`, Left $\to$ South `(0, 1)`.
- **Tile Marker Cleanliness**:
  - Ground cursors under the player's feet must not render obstructive glowing yellow bounding boxes during standard gameplay locomotion.

---

## 31. Level Editor Cross-Room Data Integrity, Wall Protection & Floor Dragging

### 31.1. Floor Drag Perimeter Wall Protection
- When dragging a multi-tile rectangular floor region (`cells.size() > 1`), any cell already occupied by a wall (`model.is_wall_at(c) == true`) must be protected and skipped.
- Dragging floor to fill an interior void or room must never silently overwrite or destroy bordering castle perimeter walls.
- Explicit replacement of a wall tile with floor is strictly reserved for single-cell clicks or the dedicated Erase / Right-Click deletion actions.

### 31.2. Cross-Room Desynchronization Prevention on Save
- Multi-room level JSON files store components categorized by room (`GreatHall`, `Chapel`, `PerimeterBarriers`, `EditorCustom`, etc.).
- When any tile, wall, window, arch, or prop is modified or erased in the editor, its coordinate is recorded in `cell_data` or `erased_cells`.
- Upon `save_to_json()`:
  - All non-`EditorCustom` rooms must be pruned of any entries matching modified or erased coordinates.
  - Erasing a wall from `PerimeterBarriers` and placing a floor in `EditorCustom` must immediately purge that wall from `PerimeterBarriers` in the saved JSON.
  - Prevents "ghost walls" where a visual wall from a base room co-exists with a walkable floor tile from a custom room upon level reload.

---

## 32. Gapless Floor Tiles, PBR Boundary Delineation & Editor Wall Transparency

### 32.1. Gapless Floor Tile Dimensions (0.0m Gaps)
- Floor tiles must be modeled with full contiguous grid dimensions: `Vector3(TILE_SIZE, 0.28, TILE_SIZE)` (`2.0m x 0.28m x 2.0m`).
- Physical voids/gaps between tiles (e.g. `TILE_SIZE - 0.08`) are strictly prohibited. Adjacent floor tiles must touch edge-to-edge seamlessly.

### 32.2. Procedural PBR Boundary Delineation (Albedo + Normal Maps)
- Because tiles touch seamlessly without physical gaps, boundary delineation is achieved via procedural PBR materials generated in `CastleFloorTextureGenerator`:
  - **Mortar / Border Seam (Albedo)**: Outer 2–3 pixels around the tile perimeter feature a darker recessed mortar seam (30–45% darker than base tone) with a smooth shoulder transition.
  - **Beveled Chamfer (Normal Map)**: Tangent-space normal map with rounded bevels along all 4 perimeter edges so directional sunlight, ambient light, and torch flickers dynamically highlight tile borders.
  - **Surface Micro-Grain**: Flagstone granite noise, gothic diamond inlays (chapel), or longitudinal timber plank grooving (wood/bridge) provides surface richness.

### 32.3. Wall Transparency & Raycast Penetration During Floor Placement
- When the Level Editor Floor tool is active (`active_tool == "floor"`):
  - All wall materials (`mat_wall_stone`, `mat_wall_trim`) switch to `BaseMaterial3D.TRANSPARENCY_ALPHA` at `28%` opacity (`albedo_color.a = 0.28`), revealing floor grids, corridors, and rooms hidden behind walls.
  - High-object physics raycasts are bypassed so mouse clicks and drag selections penetrate directly to the ground plane (`y = 0.0`), allowing unobstructed floor building through walls.
  - Switching away from the Floor tool or exiting the Level Editor immediately restores wall materials to solid opaque (`TRANSPARENCY_DISABLED`, `albedo_color.a = 1.0`).

---

## 33. Lossless Multi-Session Persistence, Equal Level Treatment & Pre-Save Validation

### 33.1. Lossless Multi-Session Persistence (`LevelEditorPersistence`)
- When saving an edited level, all rooms (including `EditorCustom` from prior edit sessions) must be preserved.
- Existing rooms must only be pruned of items whose specific coordinates were explicitly modified or erased in the current edit session.
- Untouched items in `EditorCustom` from previous edit sessions must never be overwritten or discarded.
- Additions and modifications from `cell_data` are merged losslessly into `EditorCustom`.

### 33.2. Equal Treatment of All Levels (Zero Hardcoding)
- All levels (campaign or user-created) use identical room data structures and standard room loader routines.
- Fallback level names must be dynamically derived from the file basename (`active_file_path.get_file().get_basename().capitalize()`), never hardcoded campaign strings.
- When creating a new level with a starting canvas (`builder.init_new_level()`), the initial 5x5 floor tiles are automatically seeded into `StartingHall` in the JSON data so they are never lost on first save.
- Room management (`LevelEditorRoomManager`) dynamically selects the level's existing rooms for default active room selection and deletion fallbacks rather than hardcoded room names.

### 33.3. Pre-Save Health & Integrity Checks
- Before serializing a level to disk, `LevelEditorPersistence.validate_level()` must enforce:
  1. **Rooms and Tiles Exist**: The level must contain at least one room with walkable floor tiles. Empty levels are rejected with an informative error.
  2. **Player Spawn Walkability**: The player's spawn tile (`spawn.grid`, default `(0, 0)`) must have a valid floor tile and be walkable.
  3. **Auto-Healing Spawn Floor**: If the floor at spawn was accidentally erased or missing, save logic automatically restores a walkable stone floor tile at spawn so the player never falls into the void upon level load.
  4. **Metadata Preservation**: `"spawn"` position, yaw, and `"version"` fields are preserved in the JSON structure.

---

## 34. Editor Grid Line Alignment & In-World Room Signs

### 34.1. Editor Grid Line Alignment (Tile Perimeter Framing)
- Grid lines in the Level Editor must frame the perimeter boundaries around tiles, never slice through tile centers.
- Mathematical coordinates:
  - **Tile Center**: `Vector3(gx * TILE_SIZE, 0, gz * TILE_SIZE)` = `(gx * 2.0, 0, gz * 2.0)`.
  - **Tile Boundaries (Perimeter)**: `Vector3((gx ± 0.5) * TILE_SIZE, 0, (gz ± 0.5) * TILE_SIZE)` = `(gx * 2.0 ± 1.0, 0, gz * 2.0 ± 1.0)`.
- Shader distance formula in `LevelEditorGrid`:
  - `vec2 f = abs(fract(coord / tile_size) - 0.5) * tile_size;`
  - Do not add `+ 0.5` phase shift to `coord / tile_size`, as this shifts distance zeroes directly onto tile centers.
- Dotted line interval:
  - `dot_spacing = 0.25m` (clean integer subdivision of `TILE_SIZE = 2.0m`, resulting in exactly 8 dots per tile boundary edge with matching corner intersections).

### 34.2. In-World 3D Room Signs (`LevelEditorRoomSignBuilder`)
- When the Room / Area tool is active in the Level Editor, every room with painted tiles renders a physical 3D dungeon sign in the 3D viewport.
- Spatial specifications:
  - **Centroid Snapping**: Calculate average coordinates `(avg_x, avg_z)` across all member cells of the room, and snap the sign anchor to the nearest valid floor cell inside the room (`LevelEditorRoomSignBuilder.calculate_room_center_cell`). This guarantees signs never float inside courtyards or holes of hollow/C-shaped rooms.
  - **Ground Post**: Slender dark oak timber post (`0.12m x 1.6m x 0.12m`) anchored firmly to the ground plane from `y = 0.0m` to `y = 1.6m` (`center = y = 0.8m`).
  - **Crossbeam Bracket**: Horizontal bracket at `y = 1.56m` supporting the placard.
  - **Signboard Placard**: Backing board (`width = clampf(length * 0.10 + 0.55, 1.3, 3.2)`, `height = 0.52m`, `depth = 0.06m`) positioned at `y = 1.82m` with `billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y`.
  - **Border Trim**: Accent border tinted to the room's palette color (`get_room_color(r_name)`), featuring an active emission glow when the room is currently selected.
  - **Room Name Label3D**: `font_size = 28`, `outline_size = 7`, `pixel_size = 0.0055`, `billboard = BaseMaterial3D.BILLBOARD_FIXED_Y` with high-contrast text and dark outline for clear legibility across all 4 camera rotation angles.
  - **Lifecycle**: Child of `overlay_root`; visible only during Room Editor mode and completely hidden/freed outside of room editing and during gameplay.



