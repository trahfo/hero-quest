# Hero Quest 3D: Character Systems, Archetypes & Locomotion

This document specifies the character architecture, archetype hot-swapping, parametric customization, biomechanical locomotion, and camera-relative controls.

---

## 1. Character Archetypes & Hot-Swapping

Hero Quest 3D supports instantaneous switching between four distinct character archetypes during gameplay via number keys `[1]` through `[4]`.

| Key | Archetype | Class Role | Visual Profile |
| :--- | :--- | :--- | :--- |
| **`[1]`** | **Adventurer Hero** | Balanced Warrior | Brown leather doublet, steel chestplate, short parted hair. |
| **`[2]`** | **Heavy Iron Knight** | Armored Tank | Full plate harness, closed sallet helmet, broad shoulders, massive bulk. |
| **`[3]`** | **Elven Scout** | Agile Ranger | Slender build, hooded cowl, green leather tunic, high boots. |
| **`[4]`** | **Grand Arcanist** | Magic User | Flowing robes, long wizard beard, pointed celestial mantle, arcane staff. |

### Archetype Switching Implementation:
- Swapped in real-time without resetting animations or player coordinates.
- Managed by `HumanoidVisuals` and configured via `HumanoidAppearanceData`.
- Visual containers update dynamically while the bone hierarchy (`Root/Hips/Chest/...`) remains intact.

---

## 2. Coordinate Conventions & Facing Orientation

### Standard Forward Convention: `-Z`
- Character models face along the **`-Z`** axis (Godot standard forward direction) in their rest pose.
- Nose, eyes, chest emblem, and boot toes must point along `-Z`.

### Cardinal Rotation Angles:
- **North** (`dir = Vector2i(0, -1)`): `angle = 0.0 rad` (`0°`)
- **South** (`dir = Vector2i(0, 1)`): `angle = PI rad` (`180°`)
- **East** (`dir = Vector2i(1, 0)`): `angle = -PI * 0.5 rad` (`-90°`)
- **West** (`dir = Vector2i(-1, 0)`): `angle = PI * 0.5 rad` (`+90°`)

Mathematical Formula:
```gdscript
var target_angle = atan2(-dir.x, -dir.y)
visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 16.0 * delta)
```

---

## 3. Biomechanical Locomotion & The Knee Flexion Law

The locomotion system uses procedural skeletal kinematics (`HumanoidAnimator`) synchronized to grid travel velocity.

### Strict Anatomical Knee Flexion Law
- Human knees can **ONLY bend backward** (posterior flexion towards the hamstrings/glutes). Human knees NEVER bend forward.
- In Godot's `-Z` forward coordinate system for downward-hanging bones:
  - **`Shin.rotation.x <= 0.0` AT ALL TIMES**.
  - Peak mid-swing flexion reaches `-0.96 rad` (`-55°` backward).
  - Near heel strike and mid-stance, the knee extends to `-0.04 rad` to `-0.06 rad` (nearly straight).
  - Any positive rotation (`Shin.rotation.x > 0.0`) is strictly prohibited.

### Full Kinematics Cycle:
- **Thigh & Hip Flexion**:
  - Forward swing: `Leg.rotation.x > 0` (peaks at `+0.44 rad` / `+25°` at heel strike).
  - Trailing push-off: `Leg.rotation.x < 0` (peaks at `-0.24 rad` / `-14°`).
- **Foot & Ankle Roll**:
  - Dorsiflexion (heel strike): `Foot.rotation.x > 0` (`+0.18 rad`).
  - Plantarflexion (toe push-off): `Foot.rotation.x < 0` (`-0.16 rad`).
  - Flat contact: `Foot.rotation.x = 0.0 rad`.
- **Contralateral Arm Swing**:
  - Opposite to legs: when Left Leg swings forward, Left Arm swings backward (`-0.32 rad`) and Right Arm swings forward (`+0.32 rad`).
  - Forearms flex forward (`Forearm.rotation.x >= 0`, `+0.12` to `+0.36 rad`).
- **Pelvis & Ground Clearance**:
  - Pelvis height bobs between `y = 1.025m` and `y = 1.050m`.
  - Boot soles clear floor substrates and carpets (`y >= 0.018m` during flight, flush at `y = 0.02m` at rest).

---

## 4. Continuous Multi-Tile Locomotion ("Walk Walk Walk as One")

When holding down a movement key across multiple contiguous tiles:
1. **Constant Velocity**: Speed across tile boundaries is strictly uniform ($\mathbf{v} = \Delta \mathbf{x} / \text{step\_duration}$).
2. **Delta Preservation**: The overshoot time fraction (`move_progress -= 1.0`) is preserved across tile transitions without losing frames.
3. **No Intermediate Halts**: The character never drops to zero velocity or resets the walk cycle at intermediate tile boundaries.
4. **Deceleration on Release**: Easing curves (`interp_t = sin(t * PI * 0.5)`) and idle transitions occur exclusively on the final target cell when movement ceases.

---

## 5. Isometric Camera-Relative Arrow Input Rotation

The isometric camera can be rotated in 90° increments using the `R` key. To maintain consistent spatial controls:
- **Rule**: Pressing **Arrow Down / S** must **always move the character towards the lower-left corner** of the screen, regardless of camera yaw.

### Quadrant Formula:
```gdscript
var k = posmod(roundi((45.0 - cam_yaw) / 90.0), 4)
match k:
    1: return Vector2i(-dir.y, dir.x)
    2: return Vector2i(-dir.x, -dir.y)
    3: return Vector2i(dir.y, -dir.x)
    _: return dir
```

### Resulting Directional Mappings:
| Camera Yaw | View Angle | Arrow Down (Screen Lower-Left) | Arrow Right (Screen Lower-Right) | Arrow Up (Screen Upper-Right) | Arrow Left (Screen Upper-Left) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `45°` | Default South-East | South `(0, 1)` | East `(1, 0)` | North `(0, -1)` | West `(-1, 0)` |
| `-45°` | North-East View | West `(-1, 0)` | South `(0, 1)` | East `(1, 0)` | North `(0, -1)` |
| `-135°` | North-West View | North `(0, -1)` | West `(-1, 0)` | South `(0, 1)` | East `(1, 0)` |
| `-225°` | South-West View | East `(1, 0)` | North `(0, -1)` | West `(-1, 0)` | South `(0, 1)` |
