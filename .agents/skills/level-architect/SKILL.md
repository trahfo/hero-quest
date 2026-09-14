---
name: level-architect
description: >-
  Architect and construct tile-based levels, rooms, walls, doors, props, and materials
  following the Hero Quest 3D positioning ruleset and JSON level schemas. Use whenever
  prompting a new level, adding or modifying rooms, placing architectural elements,
  or configuring procedural materials and floor items.
---

# Level Architect Skill

This skill teaches agents how to design, architect, and construct tile-based levels and rooms for Hero Quest 3D. It encapsulates the core architectural standards, geometric metrics, procedural materials, furniture and prop clearance rules, and the JSON level schema.

---

## 1. Metric Foundations & Coordinates

| Metric | Godot Dimension | Description |
| :--- | :--- | :--- |
| **Tile Size** | `TILE_SIZE = 2.0m` | Standard square grid cell width and length. |
| **Wall Thickness** | `WALL_THICKNESS = 0.9m` | Matches column shafts (`0.9m x 0.9m`). Never 2.0m cubic blocks. |
| **Wall Height** | `height = 4.5m` | Standard exterior barrier and room perimeter height. |
| **Pier / Column Height** | `height = 3.6m` | Springing height for all architectural arches and vaults. |
| **Cell Origin** | `Vector3(gx * 2.0, 0, gz * 2.0)` | Center of integer grid coordinate `(gx, gz)` at floor level. |
| **Forward Facing** | `-Z` direction | Rest pose forward vector for characters, props, and cameras. |

### Continuous Floor Substrate Rule
Every wall tile, arch pier, and doorway **must have a solid stone floor tile** (`materials.mat_floor_stone`, `size = Vector3(2.0, 0.28, 2.0)`, `y = 0.0m`) instantiated directly beneath it. Modular walls are `0.9m` thick; without floor substrates, the remaining `0.55m` margins float over empty void/skybox.

---

## 2. Modular Wall Construction & Auto-Tiling

Walls are built dynamically via `CastleWallTileFactory.create_modular_wall` based on 4 orthogonal neighbor connections (`has_left (-X)`, `has_right (+X)`, `has_up (-Z)`, `has_down (+Z)`).

```
          [has_up (-Z)]
                |
[has_left (-X)]-+- [has_right (+X)]
                |
          [has_down (+Z)]
```

### Wall Classifications:
1. **Straight X-Wall** (`has_left and has_right and not (has_up or has_down)`):
   - Box size: `Vector3(2.0, 4.5, 0.9)`. North/South walls.
2. **Straight Z-Wall** (`has_up and has_down and not (has_left or has_right)`):
   - Box size: `Vector3(0.9, 4.5, 2.0)`. East/West walls.
3. **Corner L-Junction** (1 connection in X, 1 connection in Z):
   - Central `0.9m x 0.9m` column at `(0, 0)`.
   - Connecting X-arm (`0.55m x 0.9m`) and Z-arm (`0.9m x 0.55m`).
   - Exterior corner quoin ashlar blocks on the outer diagonal corner.
4. **T-Junction** (3 connections):
   - Central `0.9m x 0.9m` column + all 3 connecting arms.
5. **4-Way Cross Junction** (4 connections):
   - Central `0.9m x 0.9m` column + all 4 connecting arms. Rotation-invariant.
6. **End Stub** (1 connection):
   - Central column + 1 connecting arm towards the neighbor.

### Wall Arm Clearance & Intrusion Prohibition
- Modular wall arms must **never extend into walkable cells, door frames, or open archways**.
- When evaluating connectivity: if a neighbor is a walkable room, corridor, or passage (`walkable == true`), the arm connection towards that direction must strictly be `false`.
- Arch piers (`type == 6` or zone containing "Pier") count as valid wall connection targets, allowing walls to meet arch column shafts flush.

---

## 3. Portals, Arches & Door Piers

### Door Pier Extension
- Column shafts (`0.9m x 0.9m`) are centered in a `2.0m` cell, leaving a `0.55m` gap to the cell boundary.
- **Never instantiate separate attached wall meshes** next to a door column.
- The pier itself expands directly along `extend_dir`:
  - Plinth base expands to `1.6m` along `extend_dir` (offset `0.2m`).
  - Column shaft expands from `0.9m` to `1.45m` (`0.9m + 0.55m`, offset `0.275m`).
  - Capital expands to `1.575m` (offset `0.2125m`).

### Mathematical Arch Spans & Heights
The ends of curved arches land directly on column capitals (`y = 3.6m`):
- **3-Tile Arch** (1 doorway): Span = `4.0m` (`2.0 * TILE_SIZE`), Radius = `2.0m`, Pier distance = `±1` tile.
- **4-Tile Arch** (2 doorways): Span = `6.0m` (`3.0 * TILE_SIZE`), Radius = `3.0m`, Pier distance = `±1.5` tiles.
- **Corridor Door Matching**: When a corridor exits one room through a door/arch, the destination room **must also have a matching door or arch**. Never leave a bare hole in the wall.
- **Corridor Width Matching**: Corridor floor width must match the portal arch spanning it. Ingress lanes must remain clear of blocking props.

---

## 4. Windows: Rules & Specifications

1. **Dedicated Wall Tile**: Modeled via `CastleWallTileFactory.create_window_wall`. Contains jambs (`0.5m x 0.9m x 4.5m`), sill shelf (`1.0m x 0.9m x 1.25m`), lintel, embrasure corner reveals, stone tracery, and stained glass.
2. **Straight Runs Only**: Windows must always be centered on straight wall runs.
3. **Never in Corners or End Stubs**: Windows in corner L-junctions or stubs are strictly forbidden.
4. **Never on Door/Arch Piers**: Never place windows in cells containing portals, arches, or pier columns.
5. **No Inter-Room Windows**: Windows between two indoor rooms are prohibited. Windows are reserved for exterior walls or walls facing open outdoor cloister gardens and courtyards.
6. **Zero Z-Fighting**: Top coping cornice is a single continuous box spanning `TILE_SIZE = 2.0m`. The lintel sits strictly below the cornice.
7. **Torches Never on Windows**: Torches and wall lamps must never be placed on window tiles. Mount them on adjacent solid wall piers.

---

## 5. Furniture, Floor Items & Relics

### Wall-Aligned Furniture Rotation
Flat-backed furniture (cupboards, drawers, bookshelves, weapon racks) must rest flat against the wall:

| Wall Location | Wall Normal (Facing Room) | Furniture `rot_y` |
| :--- | :--- | :--- |
| **West Wall** | `+X` (East) | `PI * 0.5` (`+90°`) |
| **East Wall** | `-X` (West) | `-PI * 0.5` (`-90°`) |
| **North Wall** | `+Z` (South) | `0.0` (`0°`) |
| **South Wall** | `-Z` (North) | `PI` (`180°`) |

### Carpets & Clearance
- Thickness: `0.02m`, resting flush at `y = 0.01m` (from `y = 0.00` to `y = 0.02`).
- Clearance: Tables must keep at least 1 tile clearance (`1.2m+`) from carpet borders.
- Yellow tile cursor sits above carpets at `y = 0.035m` with `render_priority = 2`.

### Tables and Chairs
- **Rule**: Every table must have at least one chair or stool.
- **Orientation**: Chairs must face into the table:
  - On `+Z` side: `rot_y = 0.0` (faces `-Z` into table).
  - On `-Z` side: `rot_y = PI` (faces `+Z` into table).
  - On `-X` side: `rot_y = -PI * 0.5` (faces `+X` into table).
  - On `+X` side: `rot_y = PI * 0.5` (faces `-X` into table).

### 3D Dropped Floor Items (`HeroQuestFloorItem`)
- Base elevation: `y = 0.15m`.
- Pedestal ring: `y = 0.03m` (`height = 0.06m`) flush on floor.
- Relic mesh: Animated sine-bobbing at `y = 0.35m - 0.41m` with slow continuous Y-rotation.
- Beacon light: `OmniLight3D` at `y = 0.45m` (`radius = 2.5m`, `energy = 0.6`, color matches item rarity).
- Attached `HeroQuestInteractable`: `interact_type = ITEM`, prompt `Press [E] or [SPACE] to pick up [Name]`.

### Treasure Chests
- Footprint: 1 tile, `walkable = false`.
- Attached `HeroQuestInteractable`: `interact_type = CHEST`.
- Parameters: `gold_bounty` (int), `is_trapped` (bool), `relic_name` (string), cardinal rotation `rot_y` (`0`, `PI*0.5`, `PI`, `-PI*0.5`).

---

## 6. Materials & Procedural Generation

### Standard Material Catalog (`CastleMaterials`)
- **Floors**: `stone`, `stone_alt`, `chapel`, `wood`, `bridge`, `courtyard`, `garden_green`, `graveyard_dirt`.
- **Architecture**: `wall_stone`, `wall_trim`, `wood_dark`, `wood_light`, `iron`, `gold`.
- **Special / VFX**: `torch_glow`, `ember`, `water_chasm`, `hay`, `cloth_red`, `gravestone`.

### Procedural PBR Floor Tiles (`CastleFloorTextureGenerator`)
- Seamless contiguous floor slabs (`Vector3(2.0, 0.28, 2.0)`). Zero physical gaps.
- Visual seams generated via procedural albedo and tangent-space normal maps:
  - **Mortar Seam**: Perimeter 2-3 pixels recessed and 30-45% darker than base tone.
  - **Beveled Chamfer Normal**: Dynamic edge highlights under sunlight and torchlight.
  - **Micro-Grain**: Granite noise, gothic diamond patterns, or timber grain grooves.

### Procedural Ashlar Relief Scattering (`CastleBrickScatterer`)
- Bricks embed `0.025m` into wall face and protrude outward to prevent GPU z-fighting.
- 2D rejection sampling with minimum `0.08m` clearance ensures blocks never overlap.

---

## 7. Level JSON Data Architecture & Recipes

Level files reside in `res://data/levels/<level_name>.json`.

### Schema Overview:
```json
{
  "name": "Level Display Name",
  "version": 1,
  "spawn": {
    "grid": [0, 0],
    "yaw": 0.0,
    "position": [0.0, 0.9, 0.0]
  },
  "rooms": {
    "GreatHall": {
      "tiles": [
        {"pos": [0, 0], "type": 1, "walkable": true, "zone": "GreatHall", "mat": "stone"}
      ],
      "walls": [
        {"pos": [0, -5], "mat": "wall_stone", "rot": 0.0, "type": 1}
      ],
      "arches": [
        {"pos": [0, -5], "axis": 0, "span": 3, "name": "Hall North Arch"}
      ],
      "chests": [
        {"pos": [2, -2], "gold": 50, "trapped": false, "relic": "Healing Potion", "rot": 0.0}
      ],
      "furniture": [],
      "props": [],
      "lights": []
    }
  }
}
```

### Tile Types:
- `0`: `EMPTY`
- `1`: `FLOOR_STONE`
- `2`: `FLOOR_WOOD`
- `3`: `FLOOR_CHAPEL`
- `4`: `FLOOR_BRIDGE`
- `5`: `FLOOR_COURTYARD`
- `6`: `WALL` / `PIER`
- `7`: `CHASM`
- `8`: `FLOOR_GRAVEYARD`

---

## 8. Procedural Recipes for Agents

### Recipe A: Adding a New Room to an Existing Level
1. **Define Grid Bounds**: Choose integer cell bounds `[min_x..max_x, min_z..max_z]`. Ensure at least 1 tile clearance from adjacent room walls.
2. **Generate Floor Tiles**:
   - Loop `gx` from `min_x` to `max_x`, `gz` from `min_z` to `max_z`.
   - Add entry to `room.tiles` with `walkable = true`, `type = 1` (or chosen floor type), `mat = "stone"`.
3. **Generate Perimeter Walls & Floor Substrates**:
   - For all cells bordering the room exterior (North `min_z - 1`, South `max_z + 1`, West `min_x - 1`, East `max_x + 1`):
   - Add wall to `room.walls` and floor substrate under wall to `room.tiles` (`walkable = false`).
4. **Connect via Portals / Corridors**:
   - Select doorway cell along connecting wall.
   - Place portal arch in `room.arches`.
   - Clear wall from doorway cell.
   - If connecting via corridor, ensure matching portal arch on destination room wall.
5. **Furnish Room**:
   - Add furniture along solid walls (use furniture rotation table).
   - Place tables with oriented chairs.
   - Add wall torches on solid wall piers at `y = 2.2m` (avoid window cells).
6. **Pre-Save Integrity Check**:
   - Verify spawn tile is walkable floor.
   - Verify no duplicate tiles at identical coordinates.

### Recipe B: Prompting a Full Level from Scratch
1. Set `"name"` and initialize `"spawn"` at `{"grid": [0, 0], "yaw": 0.0, "position": [0.0, 0.9, 0.0]}`.
2. Plan room layout graph (e.g. Entrance Courtyard -> Great Hall -> Armory / Chapel / Crypt).
3. Follow the 1-tile wall separation rule and matching door rule for all interconnecting corridors.
4. Serialize to `res://data/levels/<slug>.json` using valid JSON.
