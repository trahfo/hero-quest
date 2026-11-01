# Camera, Occlusion Ghosting & Door Flicker Prevention

## 1. Camera Smoothing
- The isometric camera follows the hero with `HeroQuestCameraSmoothing` (`scripts/hero_quest/hero_quest_camera_smoothing.gd`): frame-rate-independent exponential damping for follow (rate 8), zoom (10) and yaw (10).
- Each channel **snaps exactly onto its target** once within a tiny epsilon, so the camera is perfectly still shortly after the hero stops (< 1.6 s even after a long jump).
- `Camera3D` uses `near = 2.0`, `far = 150.0` for good depth precision (camera distance is 12-38 m).

## 2. Occlusion Ghosting
Walls and props between the camera and the hero turn into **ghosts instead of vanishing**:
- ~20% opacity (`HeroQuestCameraOcclusion.target_alpha = 0.2`, valid range 0.15-0.25).
- Glowing blue **box-edge outline plus a fresnel rim** (`rim_strength = 0.12`, `edge_strength = 0.3`, `edge_width = 0.03`, edge alpha weight 0.1 (kept faint so the hero stays readable behind the lines), kept low so the hero stays readable through the ghost) (`shaders/occlusion_fade.gdshader`), so the object is clearly still there.
- Smooth fade in (0.16 s) and out (0.22 s) with a 0.25 s linger; no snapping.
- Ray queries only run when the camera or hero moved (> 2 cm); colliders' meshes are cached, and one ghost material per mesh is reused (no per-frame material duplication).

### Why occluders once vanished completely
The fog-of-war shroud (`HeroQuestFogShroud`, `shaders/fog_of_war.gdshader`) is a full-screen transparent quad that
reads `hint_screen_texture` and writes the scene colour back as an opaque pixel. The screen copy is taken **before** the
transparent pass, so every alpha-blended object drawn before the shroud is overwritten by the opaque scene behind it.
A ghosted wall at 30% or 40% alpha therefore disappeared entirely.
**Rule:** ghost materials use `render_priority = 50` (`HeroQuestOcclusionMaterial.RENDER_PRIORITY`) so they blend *after*
the shroud. Never lower it to 0, and any new transparent world object must follow the same rule. This is covered by TEST 32.
Always verify occlusion changes with a real windowed render, not just headless tests.

## 3. Why Inner Doors Used to Flicker
Symptom: doors shimmered while the hero moved and for 1-2 s after stopping. Root causes:
1. The camera's `lerp(..., 8 * delta)` never converged, so the view kept drifting sub-pixel after the hero stopped.
2. Door frames contained **coplanar overlapping faces** (trim vs jamb inner face, top trim vs lintel underside, rebate stop vs leaf, 2-tile leaf seam, portcullis guide vs bars), which z-fight at certain camera positions.
3. A near/far range of 0.05-4000 wasted depth precision.

Fixes: exponential damping with snap, 1 cm+ offsets on all door surfaces, `near/far = 2/150`. Regression tests: `scripts/tests/test_suite_flicker_and_occlusion.gd`. When adding door geometry, keep every same-facing overlapping surface >= 5 mm apart (see `docs/tile_positioning_ruleset.md` section 40).
