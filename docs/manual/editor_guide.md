# Hero Quest 3D: Level Editor Specification & Guide

This document provides a comprehensive specification and user manual for the in-game 3D Level Editor.

---

## 1. Overview & Architecture

The Level Editor allows real-time, in-game modification and creation of levels. It operates directly on the active castle world scene and synchronizes with JSON level files (`res://data/levels/*.json`).

### Key Subsystems:
- **`LevelEditor`**: Coordinates editor lifecycle, inputs, cameras, and mode transitions.
- **`LevelEditorModel`**: Manages the underlying grid data structure, cell queries, and prop tracking.
- **`LevelEditorUI`**: Provides tool palettes, vertical category tabs, action buttons, and modal dialogs.
- **`LevelEditorToolHandler`**: Translates mouse clicks and drag events into placement and erasure operations.
- **`LevelEditorGhostPreview`**: Renders dynamic semi-transparent 3D previews for hovered placement.
- **`LevelEditorGrid`**: Renders the dotted perimeter overlay grid in the 3D viewport.
- **`LevelEditorWallAutotiler`**: Dynamically computes modular wall connections and instantiates appropriate wall tiles.
- **`LevelEditorPersistence`**: Validates level integrity, merges changes losslessly into JSON, and handles file serialization.
- **`LevelEditorHistory`**: Maintains a 50-step undo/redo stack.
- **`LevelEditorRoomManager` & `LevelEditorRoomSignBuilder`**: Handles room assignment, visual zoning overlays, and in-world 3D signs.

---

## 2. Editor Access & Controls

### Keyboard & Mouse Bindings:

| Input | Action | Behavior / Details |
| :--- | :--- | :--- |
| **`TAB`** | **Save & Toggle Editor** | Validates level, saves changes to active JSON file, and exits edit mode back to gameplay. |
| **`ESC`** | **Deselect Tool / Discard** | If a tool or item is active: deselects it, clears preview. If idle: prompts or exits without saving. |
| **Left Click** | **Place Single Item** | Instantiates active tool object on the clicked cell. |
| **Left Click + Drag (Floor)** | **Rectangular Floor Fill** | Defines bounding box `[min_x..max_x, min_z..max_z]` and fills floor tiles on release. |
| **Left Click + Drag (Wall)** | **Line Wall Run** | Batches wall registration along the dominant orthogonal axis (X or Z) and refreshes auto-tiling. |
| **Right Click** | **Category-Specific / 2-Stage Erase** | When a tool is selected (`wall`, `window`, `door`, `arch`, `chest`, `item`, `prop`, `floor`), right click ONLY deletes objects matching that specific tool category. When unselected (`none` or `erase`), Stage 1 deletes objects/walls (keeping floor); Stage 2 deletes floor tile. |
| **Hover Mouse** | **Status Bar Tile Inspector** | Hovering over any grid tile displays a live object summary in the status bar (Zone, Floor material, Wall type, Props/Doors). |
| **Middle Mouse Drag** | **Pan Camera** | Moves the overhead camera across the grid. (WASD keys also pan). |
| **`R` Key** | **Rotate Camera 90°** | Rotates camera viewpoint clockwise by 90°. |
| **`Z` / `Ctrl+Z`** | **Undo** | Reverts the last editor action from history stack (up to 50 steps). |
| **`Y` / `Ctrl+Y`** | **Redo** | Re-applies undone actions. |

---

## 3. Holographic 3D Ghost Preview (`LevelEditorGhostPreview`)

Every non-floor placeable object displays an unshaded, semi-transparent holographic preview following the cursor raycast in real-time.

### Preview Mesh Specifications:
- **Opacity / Alpha**: `alpha <= 0.25` (~80% translucent).
- **Shading**: `SHADING_MODE_UNSHADED`.
- **Culling**: `cull_mode = CULL_DISABLED` (renders two-sided geometry).
- **Render Priority**: `render_priority = 3` (renders on top of ground substrates and dotted grid).
- **Architectural Cutouts**: Windows and arches display their actual cutouts, tracery, jambs, and piers rather than simplified bounding boxes.
- **Floor Tool Exception**: The floor tool (`active_tool == "floor"`) intentionally suppresses 3D ghost meshes, relying exclusively on the 2D grid cursor highlight.

---

## 4. WYSIWYG 90° Hover Rotation & Replacement

### Real-Time Hover Rotation
- When hovering over an empty tile, the ghost preview shows the tool's base orientation.
- When hovering over a tile already occupied by the **same object type**:
  - The ghost preview rotates **90° clockwise** relative to the existing object (`rot_y = placed_rot_y + PI * 0.5`).
  - Arches and portals toggle their span axis (`axis = (placed_axis + 1) % 2`).
  - Wall decors (torches, paintings) advance to the next orthogonal wall face.
  - Isolated walls toggle between Straight X and Straight Z.
- **Placement Parity**: Clicking places the object at the exact orientation displayed by the ghost preview.

### Single-Instance Replacement Guarantee
- Placing an object onto an occupied tile automatically destroys and frees all previous object nodes at that coordinate (`LevelEditorModel._free_object_nodes_at_cell`).
- Overlapping duplicate meshes, stacked colliders, and co-planar flickering are strictly prevented.

### Placement Exceptions (`LevelEditorPlacementPolicy`)
- Symmetrical structures such as **4-way cross junctions** (`count == 4`) suppress hover rotation because they are omnidirectional. Custom exception rules can be registered via `LevelEditorPlacementPolicy.register_exception_rule()`.

---

## 5. Tool Palette & Placement Rules

### 5.1. Floor Tool
- **Rectangular Drag**: Dragging across a rectangular region fills all encompassed tiles with the selected floor material.
- **Perimeter Wall Protection**: When dragging a multi-cell region (`cells.size() > 1`), cells containing existing walls are skipped to prevent accidental destruction of perimeter walls.
- **Wall Transparency Mode**: When the Floor tool is selected, all walls become 28% translucent (`alpha = 0.28`), and high-object raycasts are bypassed so floor grids behind walls are easily editable. Solid opacity is restored on tool exit.

### 5.2. Wall Tool & Auto-Tiling
- **Line Drag Batching**: Dragging a wall line pre-registers all line cells before evaluating connectivity, preventing missing arms and gaps.
- **Auto-Tiling Resolution**: Computes neighbor connections and generates Straight X, Straight Z, L-corner (with ashlar quoins), T-junctions, or 4-way crosses.
- **Substrate Generation**: Automatically places solid stone floor tiles beneath wall segments.

### 5.3. Arches, Doors & Portals
- **Procedural Variants**:
  - **Wooden Door (Round Arch Top)**: 1-Tile (`wooden_door_1tile`) single leaf and 2-Tile (`wooden_door_2tile`) double leaf.
  - **Iron Door (Square Lintel Top)**: 1-Tile (`iron_door_1tile`) single leaf and 2-Tile (`iron_door_2tile`) double leaf.
  - **Portcullis Gate**: 1-Tile (`portcullis_1tile`) and 2-Tile (`portcullis_2tile`) vertical sliding iron lattice gates.
  - **Arch Portals**: 3-Tile single open portal and 4-Tile double open portal.
- **Door Configuration Inspector Panel (`LevelEditorDoorPanel`)**:
  - **Initial State**: `Closed (Unlocked)` (**Default**), `Closed (Locked)`, or `Open`.
  - **Required Key**: Specifies key name required to unlock (e.g. `Iron Key`, `Golden Key`, `Skeleton Key`).
  - **Consume Key On Unlock**: Checkbox toggling whether the key item is consumed from inventory when unlocked.
- **Wall Cutout & Substrates**: Placing a door or arch automatically cuts out existing wall segments, places solid stone floor substrates under the opening and flanking piers, and sets grid cell walkability to match initial state.

### 5.4. Windows
- Window tiles are dedicated 0.9m thick modular wall units with jamb columns, lintel, sill shelf, and embrasure corner reveals.
- **Placement Constraints**: Windows can only be placed on straight wall runs. They cannot be placed in corners, end stubs, arch piers, or between indoor rooms.

### 5.5. Chest Designer & Placer
- Configurable parameters: Chest relic item, gold bounty, trapped status, and 4-way cardinal facing.
- Attaches `HeroQuestInteractable` with type `CHEST` and footprint `walkable = false`.

### 5.6. Wall Decorations & Smart Snapping
- Decors (torches, framed paintings) automatically detect adjacent wall faces and snap flush to the wall surface (`offset = 0.46m`).
- **Elevations**: Torches mount at eye level `y = 2.2m`; framed paintings mount at `y = 2.0m`.
- Torches cannot be placed on window tiles.

### 5.7. Room & Area Tool
- **Walls-Only Blueprint Mode**: Activates architectural blueprint mode by hiding interior props, floors, furniture, decors, and lights while keeping walls, arches, and portals visible.
- **Zoning Overlays**: Renders translucent colored boxes (`alpha = 0.45`, `y = 0.025m`) for assigned room tiles from a 10-color palette.
- **3D In-World Room Signs**: Renders wooden dungeon placards at room centroids displaying the room name, billboarded to the camera.

---

## 6. Deletion, Persistence & Integrity

### Category-Specific & Unselected 2-Stage Deletion
1. **Tool-Specific Deletion**: When a specific tool is active in the palette (`floor`, `wall`, `window`, `door`, `arch`, `chest`, `item`, `prop`), right-clicking strictly deletes objects matching that tool's specific category, ignoring all other elements on the cell.
2. **Unselected Fallback**: When no tool is selected (`none` or `erase`):
   - **Stage 1 (Objects First)**: Erases any object, wall, prop, door, or arch at the cell while preserving the floor tile substrate.
   - **Stage 2 (Floor Second)**: If only the floor tile remains, erases the floor tile itself (making the cell an empty abyss).

### Pre-Save Health & Validation (`LevelEditorPersistence`)
Before writing any level file to disk:
1. **Room & Floor Verification**: Confirms at least one room with walkable floor tiles exists.
2. **Spawn Walkability**: Confirms the spawn cell (`(0, 0)` by default) has a valid floor and is walkable.
3. **Auto-Healing Spawn**: Automatically reconstructs a walkable stone floor tile at spawn if accidentally removed.
4. **Cross-Room Desynchronization Prevention**: Purges erased elements across all rooms in the JSON to eliminate ghost walls.
