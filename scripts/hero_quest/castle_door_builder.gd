class_name CastleDoorBuilder
extends RefCounted

## Procedural geometry builder for medieval castle doors.
## Builds 1-tile and 2-tile Wooden Doors (round top), Iron Doors (square top), and Portcullis Gates.

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

const TILE_SIZE: float = 2.0
const WALL_THICKNESS: float = 0.9
const WALL_HEIGHT: float = 4.5
# 2-tile leaves are 1.74m wide: 1cm seam in the centre, 5mm hinge gap (covered by the rebate stop)
const LEAF_TOP_CLEARANCE: float = 0.025 # leaf top never shares the plane of jamb tops / lintel underside

var materials: CastleMaterials

func _init(p_materials: CastleMaterials) -> void:
	materials = p_materials

# --- 1-TILE WOODEN DOOR (ROUND TOP) ---
func build_wooden_door_1tile(parent: Node3D, axis: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "WoodenDoor1Tile"
	parent.add_child(root)

	_build_light_tight_frame(root, 2.0, 3.25, axis, true)
	var hinge_pos = Vector3(-0.75, 0, 0) if axis == 0 else Vector3(0, 0, -0.75)
	var leaf_pivot = Node3D.new()
	leaf_pivot.name = "DoorLeafPivot"
	leaf_pivot.position = hinge_pos
	root.add_child(leaf_pivot)

	var leaf_mesh = _create_arched_wood_leaf(1.52, 3.25, 0.10, axis == 0)
	var offset = Vector3(0.75, 0, 0) if axis == 0 else Vector3(0, 0, 0.75)
	leaf_mesh.position = offset
	leaf_pivot.add_child(leaf_mesh)

	_add_door_hardware(leaf_mesh, 1.52, 3.25, axis == 0, false)
	return {"root": root, "pivots": [leaf_pivot], "type": "wooden_door_1tile", "axis": axis, "is_slide": false}

# --- 2-TILE WOODEN DOOR (ROUND TOP, DOUBLE LEAF) ---
func build_wooden_door_2tile(parent: Node3D, axis: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "WoodenDoor2Tile"
	parent.add_child(root)

	_build_light_tight_frame(root, 4.0, 3.30, axis, true)
	var left_pos = Vector3(-1.75, 0, 0) if axis == 0 else Vector3(0, 0, -1.75)
	var right_pos = Vector3(1.75, 0, 0) if axis == 0 else Vector3(0, 0, 1.75)

	var left_pivot = Node3D.new()
	left_pivot.name = "LeftLeafPivot"
	left_pivot.position = left_pos
	root.add_child(left_pivot)

	var right_pivot = Node3D.new()
	right_pivot.name = "RightLeafPivot"
	right_pivot.position = right_pos
	root.add_child(right_pivot)

	var left_mesh = _create_arched_wood_leaf(1.74, 3.30, 0.10, axis == 0, true, false)
	left_mesh.position = Vector3(0.875, 0, 0) if axis == 0 else Vector3(0, 0, 0.875)
	left_pivot.add_child(left_mesh)
	_add_door_hardware(left_mesh, 1.74, 3.30, axis == 0, true)

	var right_mesh = _create_arched_wood_leaf(1.74, 3.30, 0.10, axis == 0, true, true)
	right_mesh.position = Vector3(-0.875, 0, 0) if axis == 0 else Vector3(0, 0, -0.875)
	right_pivot.add_child(right_mesh)
	_add_door_hardware(right_mesh, 1.74, 3.30, axis == 0, false)

	return {"root": root, "pivots": [left_pivot, right_pivot], "type": "wooden_door_2tile", "axis": axis, "is_slide": false}

# --- 1-TILE IRON DOOR (SQUARE TOP) ---
func build_iron_door_1tile(parent: Node3D, axis: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "IronDoor1Tile"
	parent.add_child(root)

	_build_light_tight_frame(root, 2.0, 3.20, axis, false)
	var hinge_pos = Vector3(-0.75, 0, 0) if axis == 0 else Vector3(0, 0, -0.75)
	var leaf_pivot = Node3D.new()
	leaf_pivot.name = "DoorLeafPivot"
	leaf_pivot.position = hinge_pos
	root.add_child(leaf_pivot)

	var leaf_mesh = _create_iron_leaf(1.52, 3.20, 0.09, axis == 0)
	var offset = Vector3(0.75, 0, 0) if axis == 0 else Vector3(0, 0, 0.75)
	leaf_mesh.position = offset
	leaf_pivot.add_child(leaf_mesh)

	_add_iron_hardware(leaf_mesh, 1.52, 3.20, axis == 0, false)
	return {"root": root, "pivots": [leaf_pivot], "type": "iron_door_1tile", "axis": axis, "is_slide": false}

# --- 2-TILE IRON DOOR (SQUARE TOP, DOUBLE LEAF) ---
func build_iron_door_2tile(parent: Node3D, axis: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "IronDoor2Tile"
	parent.add_child(root)

	_build_light_tight_frame(root, 4.0, 3.20, axis, false)
	var left_pos = Vector3(-1.75, 0, 0) if axis == 0 else Vector3(0, 0, -1.75)
	var right_pos = Vector3(1.75, 0, 0) if axis == 0 else Vector3(0, 0, 1.75)

	var left_pivot = Node3D.new()
	left_pivot.name = "LeftLeafPivot"
	left_pivot.position = left_pos
	root.add_child(left_pivot)

	var right_pivot = Node3D.new()
	right_pivot.name = "RightLeafPivot"
	right_pivot.position = right_pos
	root.add_child(right_pivot)

	var left_mesh = _create_iron_leaf(1.74, 3.20, 0.09, axis == 0)
	left_mesh.position = Vector3(0.875, 0, 0) if axis == 0 else Vector3(0, 0, 0.875)
	left_pivot.add_child(left_mesh)
	_add_iron_hardware(left_mesh, 1.74, 3.20, axis == 0, true)

	var right_mesh = _create_iron_leaf(1.74, 3.20, 0.09, axis == 0)
	right_mesh.position = Vector3(-0.875, 0, 0) if axis == 0 else Vector3(0, 0, -0.875)
	right_pivot.add_child(right_mesh)
	_add_iron_hardware(right_mesh, 1.74, 3.20, axis == 0, false)

	return {"root": root, "pivots": [left_pivot, right_pivot], "type": "iron_door_2tile", "axis": axis, "is_slide": false}

# --- PORTCULLIS GATE (1-TILE & 2-TILE) ---
func build_portcullis(parent: Node3D, span_tiles: int, axis: int) -> Dictionary:
	var root = Node3D.new()
	root.name = "Portcullis_%dtile" % span_tiles
	parent.add_child(root)

	var width = 2.0 if span_tiles == 1 else 4.0
	_build_light_tight_frame(root, width, 3.25, axis, false, true)

	var gate_node = Node3D.new()
	gate_node.name = "GateLeaf"
	root.add_child(gate_node)

	var bar_count = 7 if span_tiles == 1 else 13
	var gate_w = (width - 0.46)
	var spacing = gate_w / float(bar_count - 1)
	var half_w = gate_w * 0.5

	for i in range(bar_count):
		var bar_x = -half_w + i * spacing
		var bar = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.08, 3.1, 0.08)
		b_box.material = materials.mat_iron
		bar.mesh = b_box
		bar.position = Vector3(bar_x, 1.65, 0) if axis == 0 else Vector3(0, 1.65, bar_x)
		gate_node.add_child(bar)

		# Spikes at bottom
		var spike = MeshInstance3D.new()
		var s_prism = PrismMesh.new()
		s_prism.size = Vector3(0.12, 0.25, 0.12)
		s_prism.material = materials.mat_iron
		spike.mesh = s_prism
		spike.rotation.x = PI
		spike.position = Vector3(bar_x, 0.1, 0) if axis == 0 else Vector3(0, 0.1, bar_x)
		gate_node.add_child(spike)

	# Horizontal crossbars
	for hy in [0.75, 1.75, 2.75]:
		var h_bar = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(gate_w + 0.06, 0.09, 0.12) if axis == 0 else Vector3(0.12, 0.09, gate_w + 0.06)
		h_box.material = materials.mat_iron
		h_bar.mesh = h_box
		h_bar.position = Vector3(0, hy, 0)
		gate_node.add_child(h_bar)

	return {"root": root, "pivots": [gate_node], "type": "portcullis_%dtile" % span_tiles, "axis": axis, "is_slide": true}

# --- LIGHT-TIGHT PROCEDURAL FRAME WITH REBATE STOPS ---
func _build_light_tight_frame(parent: Node3D, span: float, door_h: float, axis: int, is_arch: bool = false, with_guide: bool = false) -> void:
	var half_w = span * 0.5
	var jamb_w = 0.25
	var jamb_center = half_w - jamb_w * 0.5
	var lintel_h = WALL_HEIGHT - door_h

	# 1. Left & Right Stone Jambs (y = 0.0m up to door_h)
	for side in [-1.0, 1.0]:
		var jamb = MeshInstance3D.new()
		var j_box = BoxMesh.new()
		j_box.size = Vector3(jamb_w, door_h, WALL_THICKNESS) if axis == 0 else Vector3(WALL_THICKNESS, door_h, jamb_w)
		j_box.material = materials.mat_wall_stone
		jamb.mesh = j_box
		jamb.position = Vector3(side * jamb_center, door_h * 0.5, 0) if axis == 0 else Vector3(0, door_h * 0.5, side * jamb_center)
		parent.add_child(jamb)

		# Stone Quoin Trim Detail
		var trim = MeshInstance3D.new()
		var t_box = BoxMesh.new()
		var trim_h = door_h - 0.03 # 1.5cm clear of floor/lintel planes (no coplanar overlap)
		t_box.size = Vector3(0.06, trim_h, WALL_THICKNESS + 0.04) if axis == 0 else Vector3(WALL_THICKNESS + 0.04, trim_h, 0.06)
		t_box.material = materials.mat_wall_trim
		trim.mesh = t_box
		var trim_x = side * (half_w - jamb_w + 0.02) # inner face 1cm proud of the jamb inner face
		trim.position = Vector3(trim_x, door_h * 0.5, 0) if axis == 0 else Vector3(0, door_h * 0.5, trim_x)
		parent.add_child(trim)

		# Rebate Stop Lip (blocks light around vertical edges, sits cleanly behind leaf)
		var stop = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		var stop_h = door_h - 0.07
		s_box.size = Vector3(0.05, stop_h, 0.06) if axis == 0 else Vector3(0.06, stop_h, 0.05)
		s_box.material = materials.mat_wall_trim
		stop.mesh = s_box
		var stop_x = side * (half_w - jamb_w - 0.01)
		# z = 0.085 keeps the stop's face 5mm clear of the leaf surface at 0.05
		stop.position = Vector3(stop_x, door_h * 0.5, 0.085) if axis == 0 else Vector3(0.085, door_h * 0.5, stop_x)
		parent.add_child(stop)

		if with_guide:
			var guide = MeshInstance3D.new()
			var g_box = BoxMesh.new()
			g_box.size = Vector3(0.12, door_h - 0.03, 0.22) if axis == 0 else Vector3(0.22, door_h - 0.03, 0.12)
			g_box.material = materials.mat_iron
			guide.mesh = g_box
			var gx = side * (half_w - jamb_w + 0.07) # inner face clear of trim/jamb/bar planes
			guide.position = Vector3(gx, door_h * 0.5, 0) if axis == 0 else Vector3(0, door_h * 0.5, gx)
			parent.add_child(guide)

	# 2. Top Solid Stone Lintel / Spandrel Infill (sits cleanly above jambs from door_h to WALL_HEIGHT)
	var lintel = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(span, lintel_h, WALL_THICKNESS) if axis == 0 else Vector3(WALL_THICKNESS, lintel_h, span)
	l_box.material = materials.mat_wall_stone
	lintel.mesh = l_box
	lintel.position = Vector3(0, door_h + lintel_h * 0.5, 0)
	parent.add_child(lintel)

	# Lintel Lower Trim (blocks light over top edge)
	var top_trim = MeshInstance3D.new()
	var tt_box = BoxMesh.new()
	tt_box.size = Vector3(span + 0.04, 0.22, WALL_THICKNESS + 0.06) if axis == 0 else Vector3(WALL_THICKNESS + 0.06, 0.22, span + 0.04)
	tt_box.material = materials.mat_wall_trim
	top_trim.mesh = tt_box
	top_trim.position = Vector3(0, door_h + 0.10, 0) # underside 1cm below the lintel underside (never coplanar)
	parent.add_child(top_trim)

	if is_arch:
		# Romanesque Arch Trim Header along curved top
		var arch_r = (span - jamb_w * 2.0) * 0.5
		var segments = 10
		var d_ang = PI / float(segments)
		for i in range(segments):
			var a = i * d_ang + d_ang * 0.5
			var px = -cos(a) * arch_r
			var py = (door_h - arch_r * 0.5) + sin(a) * (arch_r * 0.6)
			var arch_stone = MeshInstance3D.new()
			var as_box = BoxMesh.new()
			var seg_len = (PI * arch_r) / float(segments) * 1.08
			if axis == 0:
				as_box.size = Vector3(seg_len, 0.22, WALL_THICKNESS + 0.04)
				arch_stone.position = Vector3(px, py, 0)
				arch_stone.rotation.z = a - PI * 0.5
			else:
				as_box.size = Vector3(WALL_THICKNESS + 0.04, 0.22, seg_len)
				arch_stone.position = Vector3(0, py, px)
				arch_stone.rotation.x = -(a - PI * 0.5)
			as_box.material = materials.mat_wall_trim
			arch_stone.mesh = as_box
			parent.add_child(arch_stone)

func _create_arched_wood_leaf(w: float, h: float, thick: float, along_x: bool, is_half_arch: bool = false, is_right: bool = false) -> Node3D:
	var node = Node3D.new()
	h -= LEAF_TOP_CLEARANCE
	var plank_count = 5
	var pw = w / float(plank_count)
	for i in range(plank_count):
		var px = -w * 0.5 + (i + 0.5) * pw
		var ph = h
		if not is_half_arch:
			var rel = absf(px) / (w * 0.5)
			ph = h - (rel * rel) * 0.30
		else:
			var rel = (px + w * 0.5) / w if not is_right else (w * 0.5 - px) / w
			ph = h - ((1.0 - rel) * (1.0 - rel)) * 0.40
		var plank = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(pw, ph, thick) if along_x else Vector3(thick, ph, pw)
		p_mesh.material = materials.mat_wood_dark if (i % 2 == 0) else materials.mat_wood_light
		plank.mesh = p_mesh
		plank.position = Vector3(px, ph * 0.5, 0) if along_x else Vector3(0, ph * 0.5, px)
		node.add_child(plank)
	return node

func _create_iron_leaf(w: float, h: float, thick: float, along_x: bool) -> Node3D:
	var node = Node3D.new()
	h -= LEAF_TOP_CLEARANCE
	var plate = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(w, h, thick) if along_x else Vector3(thick, h, w)
	p_mesh.material = materials.mat_iron
	plate.mesh = p_mesh
	plate.position = Vector3(0, h * 0.5, 0)
	node.add_child(plate)
	return node

func _add_door_hardware(leaf: Node3D, w: float, h: float, along_x: bool, is_left_leaf: bool) -> void:
	for hy in [0.65, h * 0.5, h - 0.55]:
		var strap = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(w * 0.88, 0.08, 0.14) if along_x else Vector3(0.14, 0.08, w * 0.88)
		s_mesh.material = materials.mat_iron
		strap.mesh = s_mesh
		strap.position = Vector3(0, hy, 0)
		leaf.add_child(strap)
	_add_handle(leaf, w, along_x, is_left_leaf)

func _add_iron_hardware(leaf: Node3D, w: float, h: float, along_x: bool, is_left_leaf: bool) -> void:
	for hy in [0.55, h - 0.55]:
		var band = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(w * 0.98, 0.12, 0.13) if along_x else Vector3(0.13, 0.12, w * 0.98)
		b_mesh.material = materials.mat_iron
		band.mesh = b_mesh
		band.position = Vector3(0, hy, 0)
		leaf.add_child(band)
	_add_handle(leaf, w, along_x, is_left_leaf)

func _add_handle(leaf: Node3D, w: float, along_x: bool, is_left_leaf: bool) -> void:
	var hx = (w * 0.32) if is_left_leaf else (-w * 0.32)
	var handle = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 0.05
	ring.outer_radius = 0.10
	ring.material = materials.mat_gold
	handle.mesh = ring
	handle.position = Vector3(hx, 1.25, 0.08) if along_x else Vector3(0.08, 1.25, hx)
	handle.rotation.x = PI * 0.5 if along_x else 0.0
	handle.rotation.z = PI * 0.5 if not along_x else 0.0
	leaf.add_child(handle)
