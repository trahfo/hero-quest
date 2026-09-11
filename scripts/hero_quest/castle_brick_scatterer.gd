class_name CastleBrickScatterer
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

var materials: CastleMaterials

func _init(p_materials: CastleMaterials) -> void:
	materials = p_materials

## Scatters relief ashlar bricks across a planar wall face without any overlapping.
## Uses 2D Rect2 rejection sampling with mandatory clearance padding.
func scatter_bricks_on_plane(
	parent: Node3D,
	plane_u_axis: Vector3, # Tangent along face width (e.g. Vector3.RIGHT or Vector3.FORWARD)
	face_normal: Vector3,  # Outward normal (e.g. Vector3.FORWARD, Vector3.BACK, etc.)
	center_offset: Vector3, # Center of wall face in body local space
	span_u: float,         # Available horizontal width
	span_v: float,         # Available vertical height
	seed_val: int,
	target_count: int = 5
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	var placed_rects: Array[Rect2] = []
	var padding: float = 0.08 # Strict 8cm gap between any two relief stones
	var margin_u: float = 0.12 # Edge margin
	var margin_v: float = 0.08

	var half_u: float = span_u * 0.5 - margin_u
	var half_v: float = span_v * 0.5 - margin_v

	if half_u <= 0.2 or half_v <= 0.2:
		return

	var max_attempts: int = 25
	var placed: int = 0

	for _i in range(target_count):
		for _attempt in range(max_attempts):
			var bw = rng.randf_range(0.32, 0.58)
			var bh = rng.randf_range(0.20, 0.30)
			var depth = rng.randf_range(0.045, 0.075)

			var u = rng.randf_range(-half_u + bw * 0.5, half_u - bw * 0.5)
			var v = rng.randf_range(-half_v + bh * 0.5, half_v - bh * 0.5)

			var candidate = Rect2(u - bw * 0.5, v - bh * 0.5, bw, bh)
			var padded = candidate.grow(padding)

			var overlaps = false
			for existing in placed_rects:
				if padded.intersects(existing):
					overlaps = true
					break

			if not overlaps:
				placed_rects.append(candidate)
				_instantiate_brick(parent, plane_u_axis, face_normal, center_offset, u, v, bw, bh, depth)
				placed += 1
				break

func _instantiate_brick(
	parent: Node3D,
	u_axis: Vector3,
	norm: Vector3,
	center: Vector3,
	u: float,
	v: float,
	bw: float,
	bh: float,
	depth: float
) -> void:
	var inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()

	# Size along (u_axis, UP, norm)
	var size = Vector3.ZERO
	if absf(u_axis.x) > 0.5:
		size = Vector3(bw, bh, depth)
	else:
		size = Vector3(depth, bh, bw)

	mesh.size = size
	mesh.material = materials.mat_wall_trim
	inst.mesh = mesh

	# Embed 0.025m inside the wall, protrude (depth - 0.025m) outside the wall.
	# With depth ~ 0.06m: back face is at wall_surface - 0.025m, front face at wall_surface + 0.035m.
	# Neither face is ever co-planar with the wall face, completely eliminating z-fighting!
	var embed_offset: float = depth * 0.5 - 0.025
	inst.position = center + u_axis * u + Vector3.UP * v + norm * embed_offset
	parent.add_child(inst)

## Scatters bricks on both front (+Z) and back (-Z) of an X-aligned wall
func scatter_wall_x(parent: Node3D, length: float, thickness: float, body_h: float, center_y: float, seed_val: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var count_front = rng.randi_range(3, 5)
	var count_back = rng.randi_range(3, 5)

	# Front face (+Z): outward normal is Vector3(0, 0, 1)
	scatter_bricks_on_plane(
		parent,
		Vector3(1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, center_y, thickness * 0.5),
		length,
		body_h,
		seed_val + 101,
		count_front
	)

	# Back face (-Z): outward normal is Vector3(0, 0, -1)
	scatter_bricks_on_plane(
		parent,
		Vector3(1, 0, 0),
		Vector3(0, 0, -1),
		Vector3(0, center_y, -thickness * 0.5),
		length,
		body_h,
		seed_val + 202,
		count_back
	)

## Scatters bricks on both left (-X) and right (+X) of a Z-aligned wall
func scatter_wall_z(parent: Node3D, length: float, thickness: float, body_h: float, center_y: float, seed_val: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var count_right = rng.randi_range(3, 5)
	var count_left = rng.randi_range(3, 5)

	# Right face (+X): outward normal is Vector3(1, 0, 0)
	scatter_bricks_on_plane(
		parent,
		Vector3(0, 0, 1),
		Vector3(1, 0, 0),
		Vector3(thickness * 0.5, center_y, 0),
		length,
		body_h,
		seed_val + 303,
		count_right
	)

	# Left face (-X): outward normal is Vector3(-1, 0, 0)
	scatter_bricks_on_plane(
		parent,
		Vector3(0, 0, 1),
		Vector3(-1, 0, 0),
		Vector3(-thickness * 0.5, center_y, 0),
		length,
		body_h,
		seed_val + 404,
		count_left
	)
