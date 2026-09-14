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
const LevelEditorPersistence = preload("res://scripts/hero_quest/editor/level_editor_persistence.gd")
const LevelEditorEraser = preload("res://scripts/hero_quest/editor/level_editor_eraser.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var graveyard_props: CastleGraveyardPropFactory
var wall_factory: CastleWallTileFactory
var prop_spawner: CastleLevelPropSpawner
var custom_spawner: LevelEditorCustomPropSpawner
var eraser: LevelEditorEraser

var custom_room_node: Node3D
var current_level_data: Dictionary = {}
var active_file_path: String = "res://data/levels/first_level.json"

# In-memory cell registry for editor tracking: Vector2i -> Dictionary
# State per cell: { "tile": Dictionary, "wall": Dictionary, "prop": Dictionary, "nodes": Array[Node3D] }
var cell_data: Dictionary = {}
var erased_cells: Dictionary = {}
var erased_props: Dictionary = {}
var last_save_result: Dictionary = {}

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
	eraser = LevelEditorEraser.new(self, builder)
	_ensure_custom_room()
	_load_initial_data(p_level_name)

func _ensure_custom_room() -> void:
	custom_room_node = builder.get_node_or_null("EditorCustom")
	if not custom_room_node:
		custom_room_node = Node3D.new()
		custom_room_node.name = "EditorCustom"
		builder.add_child(custom_room_node)

func _load_initial_data(p_level_name: String = "") -> void:
	current_level_data = LevelEditorPersistence.load_initial_level_data(active_file_path, builder, p_level_name)

func is_wall_at(cell: Vector2i) -> bool:
	if cell_data.has(cell) and cell_data[cell].get("wall") != null: return true
	return builder and builder.grid.has(cell) and builder.grid[cell].get("type", 0) == 6

func is_door_or_arch_at(cell: Vector2i) -> bool:
	if cell_data.has(cell):
		var p = cell_data[cell].get("prop")
		if p:
			var pt = str(p.get("type", ""))
			var at = str(p.get("arch_type", ""))
			if p.get("is_arch", false) or "door" in pt or "portcullis" in pt or "door" in at or "portcullis" in at or pt.begins_with("arch") or at.begins_with("arch"):
				return true
	if builder and builder.grid.has(cell):
		var z = str(builder.grid[cell].get("zone", ""))
		var g_prop = builder.grid[cell].get("prop")
		if "Pier" in z or "Arch" in z or "Gate" in z or "Portal" in z or "Door" in z:
			return true
		if is_instance_valid(g_prop) and (g_prop is HeroQuestDoor or g_prop.get_node_or_null("DoorController") != null or "Door" in g_prop.name or "Gate" in g_prop.name or "Arch" in g_prop.name):
			return true
	return false

func is_wall_or_portal_at(cell: Vector2i) -> bool:
	return is_wall_at(cell) or is_door_or_arch_at(cell)

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
			cell_data.erase(cell); builder.grid.erase(cell); continue
		cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
		if st["tile"] != null:
			set_floor(cell, st["tile"].get("mat", "stone"), st["tile"].get("type", 1), st["tile"].get("walkable", true))
		if st["wall"] != null:
			var w_info = st["wall"]
			if w_info.get("type") == "window":
				set_window(cell, CastleLevelData.arr_to_vec3(w_info.get("norm", [0, 0, 1])))
			else:
				set_wall(cell, int(w_info.get("orientation", -1)))
		if st["prop"] != null:
			spawn_custom_prop(cell, st["prop"])
		if st.get("zone") != null and st["zone"] != "":
			set_cell_zone(cell, st["zone"])

func set_cell_zone(cell: Vector2i, zone: String) -> void:
	if builder.grid.has(cell): builder.grid[cell]["zone"] = zone
	if cell_data.has(cell) and cell_data[cell].get("tile") != null:
		cell_data[cell]["tile"]["zone"] = zone
	for r in current_level_data.get("rooms", []):
		for t in r.get("tiles", []):
			if CastleLevelData.arr_to_vec2i(t.get("cell", [9999, 9999])) == cell:
				t["zone"] = zone; break

func get_level_name() -> String:
	var fallback = active_file_path.get_file().get_basename().capitalize()
	return str(current_level_data.get("name", fallback if fallback != "" else "Custom Realm"))

func set_level_name(p_name: String) -> void:
	current_level_data["name"] = p_name

func _clear_cell_nodes(cell: Vector2i) -> void:
	if cell_data.has(cell):
		for node in cell_data[cell].get("nodes", []):
			if is_instance_valid(node):
				if node in builder.interactive_chests: builder.interactive_chests.erase(node)
				node.queue_free()
		cell_data[cell]["nodes"].clear()

func set_floor(cell: Vector2i, mat_name: String, tile_type: int = 1, walkable: bool = true) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	var was_wall = is_wall_at(cell)
	if was_wall:
		eraser.free_object_nodes_at_cell(cell, true, false)
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
		for n in LevelEditorWallAutoTiler.get_affected_neighborhood([cell], is_wall_at):
			if n != cell and is_wall_at(n): set_wall(n)

func set_walls_batch(cells: Array[Vector2i], orientation: int = -1) -> void:
	_ensure_custom_room()
	for cell in cells:
		if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
		cell_data[cell]["wall"] = { "type": "modular", "cell": CastleLevelData.vec2i_to_arr(cell), "left": false, "right": false, "up": false, "down": false, "height": 4.5, "orientation": (orientation if orientation >= 0 else 0) }
		builder.register_tile(cell, 6, false, "Castle Walls")
	for cell in LevelEditorWallAutoTiler.get_affected_neighborhood(cells, is_wall_at):
		var o = orientation if (cells.size() == 1 and cell in cells) else -1
		set_wall(cell, o)

func set_wall(cell: Vector2i, orientation: int = -1) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	var orient = orientation
	if orient < 0 and cell_data[cell].get("wall") != null:
		orient = int(cell_data[cell]["wall"].get("orientation", 0))
	if orient < 0: orient = 0

	_clear_cell_nodes(cell)
	var conn = LevelEditorWallAutoTiler.get_wall_connections(cell, is_wall_or_portal_at)
	cell_data[cell]["wall"] = {
		"type": "modular", "cell": CastleLevelData.vec2i_to_arr(cell),
		"left": conn["left"], "right": conn["right"], "up": conn["up"], "down": conn["down"],
		"height": 4.5, "orientation": orient, "rot_y": (PI * 0.5 if orient == 1 else 0.0)
	}
	builder.register_tile(cell, 6, false, "Castle Walls")
	_add_floor_base(cell)
	var wall_node: Node3D
	if conn["count"] == 0:
		wall_node = wall_factory.create_straight_wall_z(custom_room_node, builder.grid_to_world(cell), 4.5) if orient == 1 else wall_factory.create_straight_wall_x(custom_room_node, builder.grid_to_world(cell), 4.5)
	else:
		wall_node = wall_factory.create_modular_wall(custom_room_node, builder.grid_to_world(cell), conn["left"], conn["right"], conn["up"], conn["down"], 4.5)
	cell_data[cell]["nodes"].append(wall_node)

func set_window(cell: Vector2i, norm: Vector3) -> void:
	_ensure_custom_room()
	if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	eraser.free_object_nodes_at_cell(cell, true)
	cell_data[cell]["wall"] = { "type": "window", "cell": CastleLevelData.vec2i_to_arr(cell), "norm": CastleLevelData.vec3_to_arr(norm), "height": 4.5 }
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
	if not cell_data.has(cell): cell_data[cell] = { "tile": null, "wall": null, "prop": null, "nodes": [] }
	var p_type = p_info.get("type", "")
	var is_arch = p_info.get("is_arch", false) or p_type.begins_with("arch") or p_type == "door" or "door" in p_type or "portcullis" in p_type
	var is_wall_deco = p_type in ["torch", "painting", "wall_shield", "banner"] or p_info.has("norm") or p_info.get("is_wall_deco", false)

	if is_arch or p_type == "floor_item" or p_type == "floor_key":
		cell_data[cell]["wall"] = null
		eraser.free_object_nodes_at_cell(cell, true, false)
		if cell_data[cell].get("tile") == null:
			set_floor(cell, "stone", 1, true)
		elif is_arch:
			builder.grid[cell]["walkable"] = bool(p_info.get("is_open", false))
	elif is_wall_deco:
		eraser.free_object_nodes_at_cell(cell, true, true)
	else:
		eraser.free_object_nodes_at_cell(cell, true, false)

	if not p_info.has("cell"): p_info["cell"] = CastleLevelData.vec2i_to_arr(cell)
	cell_data[cell]["prop"] = p_info
	var created_node = custom_spawner.spawn(custom_room_node, cell, p_info)
	if created_node: cell_data[cell]["nodes"].append(created_node)
	return created_node

func has_object_at_cell(cell: Vector2i) -> bool:
	if is_wall_at(cell) or (cell_data.has(cell) and cell_data[cell].get("prop") != null): return true
	if builder and builder.grid.has(cell):
		if builder.grid[cell].get("prop") != null or not builder.grid[cell].get("walkable", true): return true
		for ch in builder.interactive_chests:
			if is_instance_valid(ch) and builder.world_to_grid(ch.global_position) == cell: return true
	return false

func get_tile_summary_string(cell: Vector2i) -> String:
	var has_grid = builder and builder.grid.has(cell)
	var has_cd = cell_data.has(cell)
	if not has_grid and not has_cd: return "Tile (%d, %d) | Empty (Abyss)" % [cell.x, cell.y]
	var zone_name = "Custom"
	if has_grid and builder.grid[cell].has("zone"): zone_name = builder.grid[cell]["zone"]
	elif has_cd and cell_data[cell].get("tile") != null and cell_data[cell]["tile"].has("zone"):
		zone_name = cell_data[cell]["tile"]["zone"]

	var floor_info = "Floor (Stone)"
	if has_cd and cell_data[cell].get("tile") != null:
		floor_info = "Floor (%s)" % cell_data[cell]["tile"].get("mat", "stone").capitalize()

	var wall_info = "None"
	if has_cd and cell_data[cell].get("wall") != null:
		wall_info = "Window Wall" if cell_data[cell]["wall"].get("type", "modular") == "window" else "Modular Wall"
	elif is_wall_at(cell): wall_info = "Modular Wall"

	var obj_list: Array[String] = []
	if has_cd and cell_data[cell].get("prop") != null:
		var p_info = cell_data[cell]["prop"]
		var p_name = str(p_info.get("name", p_info.get("type", "Prop")))
		var arch_t = str(p_info.get("arch_type", ""))
		if arch_t != "": obj_list.append("Door (%s)" % p_name if ("door" in arch_t or "portcullis" in arch_t) else "Arch (%s)" % p_name)
		elif p_info.get("type") == "chest": obj_list.append("Chest (%s)" % p_name)
		elif p_info.get("type") == "item": obj_list.append("Item (%s)" % p_name)
		else: obj_list.append("Prop (%s)" % p_name)
	elif has_grid and builder.grid[cell].get("prop") != null:
		var g_prop = builder.grid[cell]["prop"]
		if is_instance_valid(g_prop): obj_list.append("Arch/Door (%s)" % g_prop.name)

	if builder:
		for ch in builder.interactive_chests:
			if is_instance_valid(ch) and builder.world_to_grid(ch.global_position) == cell:
				if "Chest" not in ", ".join(obj_list): obj_list.append("Chest")
				break

	if wall_info == "None" and obj_list.is_empty(): return "Tile (%d, %d) | Zone: %s | %s" % [cell.x, cell.y, zone_name, floor_info]
	elif wall_info != "None" and obj_list.is_empty(): return "Tile (%d, %d) | Zone: %s | %s | Wall: %s" % [cell.x, cell.y, zone_name, floor_info, wall_info]
	return "Tile (%d, %d) | Zone: %s | %s | Wall: %s | Objects: %s" % [cell.x, cell.y, zone_name, floor_info, wall_info, ", ".join(obj_list)]

# --- Eraser Delegation ---
func erase_floor_only(cell: Vector2i) -> bool: return eraser.erase_floor_only(cell)
func erase_wall_only(cell: Vector2i) -> bool: return eraser.erase_wall_only(cell)
func erase_window_only(cell: Vector2i) -> bool: return eraser.erase_window_only(cell)
func erase_door_only(cell: Vector2i) -> bool: return eraser.erase_door_only(cell)
func erase_arch_only(cell: Vector2i) -> bool: return eraser.erase_arch_only(cell)
func erase_chest_only(cell: Vector2i) -> bool: return eraser.erase_chest_only(cell)
func erase_item_only(cell: Vector2i) -> bool: return eraser.erase_item_only(cell)
func erase_prop_only(cell: Vector2i) -> bool: return eraser.erase_prop_only(cell)
func erase_unselected_fallback(cell: Vector2i) -> bool: return eraser.erase_unselected_fallback(cell)
func erase_object_at_cell(cell: Vector2i) -> bool: return eraser.erase_object_at_cell(cell)
func erase_cell(cell: Vector2i) -> void: eraser.erase_cell(cell)

func discard_unsaved_changes() -> void:
	custom_room_node = null
	_ensure_custom_room()
	cell_data.clear(); erased_cells.clear(); erased_props.clear()
	_load_initial_data()

func save_to_json(file_path: String = "") -> bool:
	var path = file_path if file_path != "" else active_file_path
	last_save_result = LevelEditorPersistence.save_level_to_json(path, current_level_data, cell_data, erased_cells, erased_props, builder)
	if not last_save_result.get("ok", false):
		push_error("Failed to write level file to: " + path + " - " + last_save_result.get("error", ""))
		return false
	print("Level Editor: Successfully saved level to ", path)
	return true
