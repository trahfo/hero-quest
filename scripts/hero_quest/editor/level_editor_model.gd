class_name LevelEditorModel
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")
const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")
const CastleLevelPropSpawner = preload("res://scripts/hero_quest/level/castle_level_prop_spawner.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")
const LevelEditorWallAutoTiler = preload("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
const LevelEditorCustomPropSpawner = preload("res://scripts/hero_quest/editor/level_editor_custom_prop_spawner.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var graveyard_props: CastleGraveyardPropFactory
var wall_factory: CastleWallTileFactory
var prop_spawner: CastleLevelPropSpawner
var custom_spawner: LevelEditorCustomPropSpawner

var custom_room_node: Node3D
var current_level_data: Dictionary = {}
var active_file_path: String = "res://data/levels/first_level.json"

# In-memory cell registry for editor tracking: Vector2i -> Dictionary
# State per cell: { "tile": Dictionary, "wall": Dictionary, "prop": Dictionary, "nodes": Array[Node3D] }
var cell_data: Dictionary = {}
var erased_cells: Dictionary = {}

func _init(p_builder: Node3D, p_file_path: String = "res://data/levels/first_level.json", p_level_name: String = "") -> void:
	builder = p_builder
	active_file_path = p_file_path
	materials = builder.materials if builder.materials else CastleMaterials.new()
	mesh_builder = builder.mesh_builder if builder.mesh_builder else CastleMeshBuilder.new(materials, builder.grid_to_world, builder.register_tile)
	prop_factory = builder.prop_factory if builder.prop_factory else CastlePropFactory.new(materials, builder.grid_to_world)
	decors = CastleDecorationFactory.new(materials, builder.grid_to_world)
	graveyard_props = CastleGraveyardPropFactory.new(materials)
	wall_factory = CastleWallTileFactory.new(materials)
	prop_spawner = CastleLevelPropSpawner.new(materials, builder.grid_to_world, mesh_builder, prop_factory)
	custom_spawner = LevelEditorCustomPropSpawner.new(builder, materials, mesh_builder, prop_factory, decors, graveyard_props, prop_spawner)
	_ensure_custom_room()
	_load_initial_data(p_level_name)

func _ensure_custom_room() -> void:
	custom_room_node = builder.get_node_or_null("EditorCustom")
	if not custom_room_node:
		custom_room_node = Node3D.new()
		custom_room_node.name = "EditorCustom"
		builder.add_child(custom_room_node)

func _load_initial_data(p_level_name: String = "") -> void:
	if FileAccess.file_exists(active_file_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(active_file_path))
		if parsed is Dictionary: current_level_data = parsed
	if current_level_data.is_empty():
		var display_name = p_level_name if p_level_name != "" else "Untitled Level"
		current_level_data = {
			"level_id": active_file_path.get_file().get_basename(),
			"name": display_name,
			"rooms": []
		}

func is_wall_at(cell: Vector2i) -> bool:
	if cell_data.has(cell) and cell_data[cell].get("wall") != null: return true
	return builder.grid.has(cell) and builder.grid[cell].get("type", 0) == 6

func is_door_or_arch_at(cell: Vector2i) -> bool:
	if cell_data.has(cell):
		var p = cell_data[cell].get("prop")
		if p and p.get("is_arch", false): return true
	if builder.grid.has(cell):
		var z = str(builder.grid[cell].get("zone", ""))
		if "Pier" in z or "Arch" in z or "Gate" in z or "Portal" in z: return true
	return false

func capture_cell_states(cells: Array) -> Dictionary:
	var snapshot: Dictionary = {}
	for cell in cells:
		var z = builder.grid[cell].get("zone", "Custom") if builder.grid.has(cell) else "Custom"
		if cell_data.has(cell):
			var cd = cell_data[cell]
			snapshot[cell] = {
				"exists": true, "zone": z,
				"tile": cd.get("tile", {}).duplicate(true) if cd.get("tile") else null,
				"wall": cd.get("wall", {}).duplicate(true) if cd.get("wall") else null,
				"prop": cd.get("prop", {}).duplicate(true) if cd.get("prop") else null
			}
		elif builder.grid.has(cell):
			var info = builder.grid[cell]
			snapshot[cell] = { "exists": true, "wall": null, "prop": null, "zone": z, "tile": { "type": info.get("type", 1), "walkable": info.get("walkable", true), "zone": z, "mat": "stone" } }
		else:
			snapshot[cell] = { "exists": false, "tile": null, "wall": null, "prop": null, "zone": "" }
	return snapshot

func apply_cell_states(state_dict: Dictionary) -> void:
	_ensure_custom_room()
	for cell in state_dict.keys():
		var st = state_dict[cell]
		_clear_cell_nodes(cell)
		if not st["exists"]:
			cell_data.erase(cell)
			builder.grid.erase(cell)
			continue

		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
		if st["tile"] != null:
			set_floor(cell, st["tile"].get("mat", "stone"), st["tile"].get("type", 1), st["tile"].get("walkable", true))
		if st["wall"] != null:
			var w_info = st["wall"]
			if w_info.get("type") == "window":
				set_window(cell, CastleLevelData.arr_to_vec3(w_info.get("norm", [0, 0, 1])))
			else:
				set_wall(cell)
		if st["prop"] != null:
			spawn_custom_prop(cell, st["prop"])
		if st.get("zone") != null and st["zone"] != "":
			set_cell_zone(cell, st["zone"])

func set_cell_zone(cell: Vector2i, zone: String) -> void:
	if builder.grid.has(cell):
		builder.grid[cell]["zone"] = zone
	if cell_data.has(cell) and cell_data[cell].get("tile") != null:
		cell_data[cell]["tile"]["zone"] = zone
	for r in current_level_data.get("rooms", []):
		for t in r.get("tiles", []):
			if CastleLevelData.arr_to_vec2i(t.get("cell", [9999, 9999])) == cell:
				t["zone"] = zone
				break

func get_level_name() -> String:
	return str(current_level_data.get("name", "Untitled Level"))

func set_level_name(p_name: String) -> void:
	current_level_data["name"] = p_name

func _clear_cell_nodes(cell: Vector2i) -> void:
	if cell_data.has(cell):
		for node in cell_data[cell].get("nodes", []):
			if is_instance_valid(node):
				if node in builder.interactive_chests:
					builder.interactive_chests.erase(node)
				node.queue_free()
		cell_data[cell]["nodes"].clear()

func set_floor(cell: Vector2i, mat_name: String, tile_type: int = 1, walkable: bool = true) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell):
		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	var was_wall = is_wall_at(cell)
	if was_wall:
		_clear_cell_wall_nodes(cell)
		cell_data[cell]["wall"] = null
	erased_cells.erase(cell)
	var cur_zone = builder.grid[cell].get("zone", "Custom") if builder.grid.has(cell) else "Custom"
	cell_data[cell]["tile"] = { "cell": CastleLevelData.vec2i_to_arr(cell), "type": tile_type, "walkable": walkable, "zone": cur_zone, "mat": mat_name }
	builder.register_tile(cell, tile_type, walkable, cur_zone)

	if tile_type != 7:
		var mat = CastleLevelData.name_to_mat(mat_name, materials)
		var m_inst = MeshInstance3D.new()
		var b_mesh = BoxMesh.new(); b_mesh.size = Vector3(2.0, 0.28, 2.0); b_mesh.material = mat
		m_inst.mesh = b_mesh; m_inst.position = builder.grid_to_world(cell) + Vector3(0.0, -0.14, 0.0)
		custom_room_node.add_child(m_inst)
		cell_data[cell]["nodes"].append(m_inst)

	if was_wall:
		var affected = LevelEditorWallAutoTiler.get_affected_neighborhood([cell], is_wall_at)
		for n in affected:
			if n != cell and is_wall_at(n): set_wall(n)

func set_walls_batch(cells: Array[Vector2i]) -> void:
	_ensure_custom_room()
	for cell in cells:
		if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
		cell_data[cell]["wall"] = { "type": "modular", "cell": CastleLevelData.vec2i_to_arr(cell), "left": false, "right": false, "up": false, "down": false, "height": 4.5 }
		builder.register_tile(cell, 6, false, "Castle Walls")
	for cell in LevelEditorWallAutoTiler.get_affected_neighborhood(cells, is_wall_at): set_wall(cell)

func set_wall(cell: Vector2i) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell):
		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }

	_clear_cell_nodes(cell)

	var conn = LevelEditorWallAutoTiler.get_wall_connections(cell, is_wall_at)
	cell_data[cell]["wall"] = {
		"type": "modular", "cell": CastleLevelData.vec2i_to_arr(cell),
		"left": conn["left"], "right": conn["right"], "up": conn["up"], "down": conn["down"], "height": 4.5
	}
	builder.register_tile(cell, 6, false, "Castle Walls")

	_add_floor_base(cell)
	var wall_node = wall_factory.create_modular_wall(custom_room_node, builder.grid_to_world(cell), conn["left"], conn["right"], conn["up"], conn["down"], 4.5)
	cell_data[cell]["nodes"].append(wall_node)

func set_window(cell: Vector2i, norm: Vector3) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell):
		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	_clear_cell_nodes(cell)
	cell_data[cell]["wall"] = {
		"type": "window", "cell": CastleLevelData.vec2i_to_arr(cell),
		"norm": CastleLevelData.vec3_to_arr(norm), "height": 4.5
	}
	builder.register_tile(cell, 6, false, "Castle Walls")
	_add_floor_base(cell)
	var win_node = wall_factory.create_window_wall(custom_room_node, builder.grid_to_world(cell), norm, 4.5)
	cell_data[cell]["nodes"].append(win_node)

func _add_floor_base(cell: Vector2i) -> void:
	var f_inst = MeshInstance3D.new()
	var fb_mesh = BoxMesh.new(); fb_mesh.size = Vector3(2.0, 0.28, 2.0); fb_mesh.material = materials.mat_floor_stone
	f_inst.mesh = fb_mesh; f_inst.position = builder.grid_to_world(cell) + Vector3(0.0, -0.14, 0.0)
	custom_room_node.add_child(f_inst)
	cell_data[cell]["nodes"].append(f_inst)

func spawn_custom_prop(cell: Vector2i, p_info: Dictionary) -> Node3D:
	_ensure_custom_room()
	if not cell_data.has(cell):
		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }

	var p_type = p_info.get("type", "")
	var is_arch = p_info.get("is_arch", false) or p_type.begins_with("arch") or p_type == "door"
	if is_arch:
		cell_data[cell]["wall"] = null
		_clear_cell_wall_nodes(cell)
		if cell_data[cell].get("tile") == null:
			set_floor(cell, "stone", 1, true)
		else:
			builder.grid[cell]["walkable"] = true

	cell_data[cell]["prop"] = p_info

	var created_node = custom_spawner.spawn(custom_room_node, cell, p_info)
	if created_node:
		cell_data[cell]["nodes"].append(created_node)
	return created_node

func _clear_cell_wall_nodes(cell: Vector2i) -> void:
	_free_object_nodes_at_cell(cell, true)

func _is_floor_node(node: Node) -> bool:
	if not (node is Node3D) or not is_instance_valid(node): return false
	if node is MeshInstance3D and node.position.y < 0.0: return true
	if node is StaticBody3D and node.position.y < 0.2:
		for c in node.get_children():
			if (c is CollisionShape3D or c is MeshInstance3D) and c.position.y > 0.05: return false
		return true
	return false

func _free_object_nodes_at_cell(cell: Vector2i, keep_floor: bool = true) -> void:
	if cell_data.has(cell):
		var remaining: Array[Node3D] = []
		for node in cell_data[cell].get("nodes", []):
			if is_instance_valid(node):
				if keep_floor and _is_floor_node(node): remaining.append(node)
				else:
					if node in builder.interactive_chests: builder.interactive_chests.erase(node)
					node.queue_free()
		cell_data[cell]["nodes"] = remaining

	var target_global = builder.to_global(builder.grid_to_world(cell))
	_find_and_free_spatial_nodes(builder, target_global, keep_floor)

func _find_and_free_spatial_nodes(parent: Node, target_global: Vector3, keep_floor: bool) -> void:
	if not is_instance_valid(parent): return
	if parent == builder:
		for room in builder.get_children():
			if room is Node3D and is_instance_valid(room) and not room.name.begins_with("LevelEditor") and room.name != "EditorGrid":
				_find_and_free_spatial_nodes(room, target_global, keep_floor)
		return

	for child in parent.get_children():
		if not (child is Node3D) or not is_instance_valid(child) or child.name.begins_with("LevelEditor"): continue
		var dist = Vector2(child.global_position.x - target_global.x, child.global_position.z - target_global.z).length()
		if dist < 0.65:
			if keep_floor and _is_floor_node(child): continue
			if child in builder.interactive_chests: builder.interactive_chests.erase(child)
			child.queue_free()
		elif child.get_child_count() > 0 and not (child is MeshInstance3D) and not (child is StaticBody3D):
			_find_and_free_spatial_nodes(child, target_global, keep_floor)

func erase_object_at_cell(cell: Vector2i) -> bool:
	var had_obj = false
	var was_wall = is_wall_at(cell)

	if cell_data.has(cell):
		if cell_data[cell].get("prop") != null:
			had_obj = true
			cell_data[cell]["prop"] = null
		if cell_data[cell].get("wall") != null:
			had_obj = true
			cell_data[cell]["wall"] = null

	var has_grid_prop = builder.grid.has(cell) and builder.grid[cell].get("prop") != null
	if was_wall or has_grid_prop:
		had_obj = true

	if not had_obj:
		return false

	_free_object_nodes_at_cell(cell, true)

	if was_wall:
		set_floor(cell, "stone", 1, true)
	else:
		if cell_data.has(cell) and cell_data[cell].get("tile") != null:
			builder.grid[cell]["walkable"] = cell_data[cell]["tile"].get("walkable", true)
			builder.grid[cell]["type"] = cell_data[cell]["tile"].get("type", 1)
			builder.grid[cell]["prop"] = null
		elif builder.grid.has(cell):
			builder.grid[cell]["walkable"] = true
			builder.grid[cell]["prop"] = null

	return true

func erase_cell(cell: Vector2i) -> void:
	var was_wall = is_wall_at(cell)
	_free_object_nodes_at_cell(cell, false)
	cell_data.erase(cell)
	erased_cells[cell] = true
	builder.grid.erase(cell)
	if was_wall:
		var affected = LevelEditorWallAutoTiler.get_affected_neighborhood([cell], is_wall_at)
		for n in affected:
			if n != cell and is_wall_at(n):
				set_wall(n)

func discard_unsaved_changes() -> void:
	_ensure_custom_room()
	for c in custom_room_node.get_children():
		c.queue_free()
	cell_data.clear()
	erased_cells.clear()
	_load_initial_data()

func save_to_json(file_path: String = "") -> bool:
	var path = file_path if file_path != "" else active_file_path
	var custom_room: Dictionary = {
		"name": "EditorCustom", "tiles": [], "carpets": [], "pillars": [], "torches": [],
		"arches": [], "props": [], "lights": [], "windows": [], "modular_walls": []
	}
	for d in cell_data.values():
		if d.get("tile") != null: custom_room["tiles"].append(d["tile"])
		if d.get("wall") != null:
			var w = d["wall"]
			if w.get("type") == "window": custom_room["windows"].append(w)
			else: custom_room["modular_walls"].append(w)
		if d.get("prop") != null:
			var p = d["prop"]
			if p.get("is_arch", false): custom_room["arches"].append(p)
			else: custom_room["props"].append(p)

	var touched: Dictionary = {}
	for c in cell_data.keys(): touched[c] = true
	for c in erased_cells.keys(): touched[c] = true

	var rooms: Array = current_level_data.get("rooms", [])
	var idx = -1
	for i in range(rooms.size()):
		var r = rooms[i]
		if r.get("name") == "EditorCustom":
			idx = i
			continue
		_prune_room_cells(r, touched)

	if idx >= 0: rooms[idx] = custom_room
	else: rooms.append(custom_room)
	current_level_data["rooms"] = rooms

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to write level file to: " + path)
		return false
	file.store_string(JSON.stringify(current_level_data, "\t"))
	file.close()
	print("Level Editor: Successfully saved level to ", path)
	return true

func _prune_room_cells(room: Dictionary, touched: Dictionary) -> void:
	for k in ["modular_walls", "windows", "tiles", "props", "arches", "pillars", "torches"]:
		if not room.has(k) or not (room[k] is Array): continue
		var filtered = []
		for item in room[k]:
			if item is Dictionary and item.has("cell"):
				var c = CastleLevelData.arr_to_vec2i(item["cell"])
				if touched.has(c): continue
			filtered.append(item)
		room[k] = filtered
