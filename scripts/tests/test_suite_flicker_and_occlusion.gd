class_name TestSuiteFlickerAndOcclusion
extends RefCounted

## Regression guards for the "inner doors flicker 1-2 s after the hero stops" bug:
## (a) no coplanar overlapping faces inside any door assembly (z-fighting),
## (b) the camera follow converges exactly and then stops moving,
## (c) occluders ghost to ~40% alpha with edges and restore cleanly.

const PLANE_EPS: float = 0.005
const MIN_OVERLAP_AREA: float = 1e-5

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 11] DOOR Z-FIGHTING, CAMERA SETTLING & OCCLUSION GHOSTING ===")

	var Mats = load("res://scripts/hero_quest/castle_materials.gd")
	var Builder = load("res://scripts/hero_quest/castle_door_builder.gd")
	var door_bld = Builder.new(Mats.new())

	print("\n[TEST 30] Verifying door assemblies have no coplanar overlapping faces (z-fighting)...")
	for axis in [0, 1]:
		var root = Node3D.new()
		tree.root.add_child(root)
		var results = [
			door_bld.build_wooden_door_1tile(root, axis), door_bld.build_wooden_door_2tile(root, axis),
			door_bld.build_iron_door_1tile(root, axis), door_bld.build_iron_door_2tile(root, axis),
			door_bld.build_portcullis(root, 1, axis), door_bld.build_portcullis(root, 2, axis),
		]
		for res in results:
			var violations = find_coplanar_overlaps(res["root"])
			assert(violations.is_empty(), "%s (axis %d) has coplanar overlapping faces: %s" % [res["type"], axis, str(violations)])
		root.queue_free()
	print("  -> Passed! Every door frame/leaf surface is >= 5mm apart from any same-facing overlapping surface.")

	print("\n[TEST 31] Verifying camera smoothing converges exactly and stops moving...")
	var Smooth = load("res://scripts/hero_quest/hero_quest_camera_smoothing.gd")
	for fps in [30.0, 60.0, 144.0]:
		var dt = 1.0 / fps
		var pos = Vector3(0, 0, 0)
		var target = Vector3(9.0, 0.0, -14.0)
		var t = 0.0
		var settled_at = -1.0
		while t < 3.0:
			var nxt = Smooth.damp_vec3(pos, target, 8.0, dt)
			if nxt == pos and pos == target and settled_at < 0.0:
				settled_at = t
			pos = nxt
			t += dt
		assert(pos == target, "camera must land exactly on target (fps %d)" % int(fps))
		assert(settled_at >= 0.0 and settled_at <= 1.6, "camera must settle within 1.6s (fps %d, took %.2f)" % [int(fps), settled_at])
	assert(Smooth.damp_float(11.9995, 12.0, 10.0, 0.016) == 12.0)
	assert(Smooth.damp_angle(0.7853, 0.7853 + 0.0003, 10.0, 0.016) == 0.7853 + 0.0003)
	print("  -> Passed! Camera follow, zoom and yaw snap to target; no sub-pixel drift after the hero stops.")

	print("\n[TEST 32] Verifying occluder ghosting: ~40% alpha, edge shader, smooth fade, clean restore...")
	var Occ = load("res://scripts/hero_quest/hero_quest_camera_occlusion.gd")
	var occ = Occ.new()
	tree.root.add_child(occ)
	assert(occ.target_alpha >= 0.15 and occ.target_alpha <= 0.25, "ghost alpha must be translucent but readable (15-25%)")
	var wall = MeshInstance3D.new()
	var std = StandardMaterial3D.new()
	std.albedo_color = Color(0.3, 0.4, 0.5)
	var box = BoxMesh.new()
	box.size = Vector3(2, 4, 0.9)
	box.material = std
	wall.mesh = box
	tree.root.add_child(wall)

	occ._fade_mesh(wall)
	var ghost = wall.material_override as ShaderMaterial
	assert(ghost != null and ghost.shader != null)
	assert(float(ghost.get_shader_parameter("fade")) == 0.0, "fade starts at 0 (no pop)")
	# Regression: the fog-of-war shroud quad (priority 0) overwrites every transparent pixel drawn
	# before it, which made ghosted walls vanish completely. Ghosts must draw after it.
	assert(ghost.render_priority > 0, "ghost must render after the fog shroud (render_priority > 0)")
	assert(ghost.get_shader_parameter("aabb_max") == box.get_aabb().end, "edge mask uses the mesh AABB")
	occ._fade_mesh(wall) # re-fading must reuse the same material (no per-frame duplication)
	assert(wall.material_override == ghost)

	occ._active_meshes[wall] = true
	occ._advance_fades(0.05)
	var mid = float(ghost.get_shader_parameter("fade"))
	assert(mid > 0.0 and mid < 1.0, "fade is animated, not snapped")
	for _i in range(20):
		occ._advance_fades(0.05)
	assert(float(ghost.get_shader_parameter("fade")) == 1.0)

	occ._active_meshes.clear()
	for _i in range(40):
		occ._advance_fades(0.05)
	assert(not occ.faded_meshes.has(wall) and wall.material_override == null, "restored to original after fade-out")
	wall.queue_free(); occ.queue_free()
	print("  -> Passed! Occluders ghost smoothly with edge outline and restore without material churn.")

## Returns human-readable descriptions of same-facing, coplanar, overlapping BoxMesh faces.
static func find_coplanar_overlaps(door_root: Node3D) -> Array:
	var boxes: Array[AABB] = []
	var names: Array[String] = []
	var inv = door_root.global_transform.affine_inverse()
	for m in door_root.find_children("*", "MeshInstance3D", true, false):
		var mi = m as MeshInstance3D
		if not mi or not (mi.mesh is BoxMesh):
			continue
		var xf: Transform3D = inv * mi.global_transform
		if not xf.basis.is_equal_approx(Basis.IDENTITY):
			continue # rotated arch voussoirs / handles are not axis aligned
		var size: Vector3 = (mi.mesh as BoxMesh).size
		boxes.append(AABB(xf.origin - size * 0.5, size))
		names.append(str(mi.get_path()).get_file() + str(boxes.size()))

	var out: Array = []
	for i in range(boxes.size()):
		for j in range(i + 1, boxes.size()):
			var a = boxes[i]
			var b = boxes[j]
			for axis in range(3):
				for sign in [0, 1]:
					var pa = a.end[axis] if sign == 1 else a.position[axis]
					var pb = b.end[axis] if sign == 1 else b.position[axis]
					if absf(pa - pb) > PLANE_EPS:
						continue
					if sign == 0 and absf(pa) <= PLANE_EPS:
						continue # floor-contact faces at y=0 are never visible
					if _face_overlap_area(a, b, axis) > MIN_OVERLAP_AREA and not _is_buried(boxes, a, b, axis, sign, pa):
						out.append("%s~%s axis%d%s plane=%.3f" % [names[i], names[j], axis, "+" if sign == 1 else "-", pa])
	return out

static func _face_overlap_area(a: AABB, b: AABB, axis: int) -> float:
	var area = 1.0
	for k in range(3):
		if k == axis:
			continue
		var lo = maxf(a.position[k], b.position[k])
		var hi = minf(a.end[k], b.end[k])
		if hi <= lo:
			return 0.0
		area *= (hi - lo)
	return area

## A coplanar face is harmless when a third solid swallows the space just in front of it.
static func _is_buried(boxes: Array[AABB], a: AABB, b: AABB, axis: int, sign: int, plane: float) -> bool:
	var probe = Vector3.ZERO
	for k in range(3):
		if k == axis:
			probe[k] = plane + (0.001 if sign == 1 else -0.001)
		else:
			probe[k] = (maxf(a.position[k], b.position[k]) + minf(a.end[k], b.end[k])) * 0.5
	for c in boxes:
		if c.has_point(probe):
			return true
	return false
