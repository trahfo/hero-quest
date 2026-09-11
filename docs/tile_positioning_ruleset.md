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
  - Placed flanking the cemetery gate threshold and along walking rows to provide eerie gothic illumination.



