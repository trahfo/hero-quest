class_name LevelEditorPersistence
extends RefCounted

const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")

static func load_initial_level_data(file_path: String, builder: Node3D, default_name: String = "") -> Dictionary:
	var data: Dictionary = {}
	if FileAccess.file_exists(file_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		if parsed is Dictionary:
			data = parsed

	if data.is_empty():
		var display_name = default_name.strip_edges()
		if display_name.is_empty():
			display_name = file_path.get_file().get_basename().capitalize()
		if display_name.is_empty():
			display_name = "Custom Realm"

		data = {
			"level_id": file_path.get_file().get_basename(),
			"name": display_name,
			"rooms": [],
			"spawn": {"grid": [0.0, 0.0], "yaw": 45.0},
			"version": 1.0
		}

		if builder and builder.grid and not builder.grid.is_empty():
			var start_tiles: Array = []
			for cell in builder.grid.keys():
				var info = builder.grid[cell]
				var t_type = int(info.get("type", 1))
				var walkable = bool(info.get("walkable", true))
				var zone = str(info.get("zone", display_name))
				var alt = (cell.x + cell.y) % 2 == 0
				var mat = "stone" if alt else "stone_alt"
				start_tiles.append({
					"cell": CastleLevelData.vec2i_to_arr(cell),
					"type": t_type,
					"walkable": walkable,
					"zone": zone,
					"mat": mat
				})
			data["rooms"].append({
				"name": "StartingHall",
				"tiles": start_tiles,
				"carpets": [], "pillars": [], "torches": [], "arches": [],
				"props": [], "lights": [], "windows": [], "modular_walls": []
			})

	if not data.has("spawn") or not (data["spawn"] is Dictionary):
		data["spawn"] = {"grid": [0.0, 0.0], "yaw": 45.0}
	if not data.has("version"):
		data["version"] = 1.0

	return data

static func validate_level(level_data: Dictionary, builder: Node3D, cell_data: Dictionary) -> Dictionary:
	var rooms: Array = level_data.get("rooms", [])
	var has_tiles = false
	for r in rooms:
		if r is Dictionary and r.has("tiles") and (r["tiles"] as Array).size() > 0:
			has_tiles = true
			break
	if not has_tiles:
		for cd in cell_data.values():
			if cd.get("tile") != null:
				has_tiles = true
				break
	if not has_tiles and builder and builder.grid and not builder.grid.is_empty():
		has_tiles = true

	if not has_tiles:
		return {"valid": false, "error": "Level must contain at least one room with floor tiles."}

	var spawn_cell = Vector2i(0, 0)
	if level_data.has("spawn") and level_data["spawn"] is Dictionary and level_data["spawn"].has("grid"):
		spawn_cell = CastleLevelData.arr_to_vec2i(level_data["spawn"]["grid"])

	var needs_spawn_floor = false
	if cell_data.has(spawn_cell):
		if cell_data[spawn_cell].get("tile") == null:
			needs_spawn_floor = true
	elif builder and builder.grid:
		if not builder.grid.has(spawn_cell):
			needs_spawn_floor = true
		elif not builder.is_tile_walkable(spawn_cell):
			needs_spawn_floor = true

	return {
		"valid": true,
		"error": "",
		"spawn_cell": spawn_cell,
		"needs_spawn_floor": needs_spawn_floor
	}

static func save_level_to_json(file_path: String, current_level_data: Dictionary, cell_data: Dictionary, erased_cells: Dictionary, erased_props: Dictionary, builder: Node3D) -> Dictionary:
	if file_path.strip_edges().is_empty():
		return {"ok": false, "error": "Invalid empty file path.", "notice": ""}

	var val = validate_level(current_level_data, builder, cell_data)
	if not val.get("valid", false):
		return {"ok": false, "error": val.get("error", "Level validation failed."), "notice": ""}

	var notice = ""
	if val.get("needs_spawn_floor", false):
		var sc: Vector2i = val["spawn_cell"]
		if not cell_data.has(sc):
			cell_data[sc] = {"tile": null, "wall": null, "prop": null, "nodes": []}
		var cur_zone = builder.grid[sc].get("zone", "Spawn") if (builder and builder.grid and builder.grid.has(sc)) else "Spawn"
		cell_data[sc]["tile"] = {
			"cell": CastleLevelData.vec2i_to_arr(sc),
			"type": 1,
			"walkable": true,
			"zone": cur_zone,
			"mat": "stone"
		}
		cell_data[sc]["wall"] = null
		erased_cells.erase(sc)
		if builder:
			builder.register_tile(sc, 1, true, cur_zone)
		notice = "Walkable floor tile at spawn %s verified." % str(sc)

	var touched: Dictionary = {}
	for c in cell_data.keys(): touched[c] = true
	for c in erased_cells.keys(): touched[c] = true
	for c in erased_props.keys(): touched[c] = true

	var rooms: Array = current_level_data.get("rooms", [])
	_prune_all_rooms(rooms, touched, cell_data, erased_cells, erased_props, builder)

	var custom_additions = {
		"tiles": [], "modular_walls": [], "windows": [], "arches": [], "props": []
	}
	for cell in cell_data.keys():
		var d = cell_data[cell]
		if d.get("tile") != null:
			var t = d["tile"].duplicate(true)
			if not t.has("cell"): t["cell"] = CastleLevelData.vec2i_to_arr(cell)
			custom_additions["tiles"].append(t)
		if d.get("wall") != null:
			var w = d["wall"].duplicate(true)
			if not w.has("cell"): w["cell"] = CastleLevelData.vec2i_to_arr(cell)
			if w.get("type") == "window": custom_additions["windows"].append(w)
			else: custom_additions["modular_walls"].append(w)
		if d.get("prop") != null:
			var p = d["prop"].duplicate(true)
			if not p.has("cell"): p["cell"] = CastleLevelData.vec2i_to_arr(cell)
			if p.get("is_arch", false): custom_additions["arches"].append(p)
			else: custom_additions["props"].append(p)

	_merge_custom_additions(rooms, custom_additions)
	current_level_data["rooms"] = rooms
	current_level_data["level_id"] = file_path.get_file().get_basename()

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return {"ok": false, "error": "Failed to write file to: " + file_path, "notice": ""}
	file.store_string(JSON.stringify(current_level_data, "\t"))
	file.close()
	return {"ok": true, "error": "", "notice": notice}

static func _prune_all_rooms(rooms: Array, touched: Dictionary, cell_data: Dictionary, erased_cells: Dictionary, erased_props: Dictionary, builder: Node3D) -> void:
	for r in rooms:
		if not (r is Dictionary): continue
		_prune_room_tiles(r, erased_cells, cell_data)
		_prune_room_walls(r, erased_cells, cell_data)
		_prune_room_props(r, touched, erased_cells, erased_props, cell_data)
		_prune_room_spatial_items(r, erased_cells, builder)

static func _prune_room_tiles(room: Dictionary, erased_cells: Dictionary, cell_data: Dictionary) -> void:
	if not room.has("tiles") or not (room["tiles"] is Array): return
	var filtered = []
	for item in room["tiles"]:
		if item is Dictionary and item.has("cell"):
			var c = CastleLevelData.arr_to_vec2i(item["cell"])
			if erased_cells.has(c): continue
			if cell_data.has(c) and cell_data[c].get("tile") != null: continue
		filtered.append(item)
	room["tiles"] = filtered

static func _prune_room_walls(room: Dictionary, erased_cells: Dictionary, cell_data: Dictionary) -> void:
	for k in ["modular_walls", "windows"]:
		if not room.has(k) or not (room[k] is Array): continue
		var filtered = []
		for item in room[k]:
			if item is Dictionary and item.has("cell"):
				var c = CastleLevelData.arr_to_vec2i(item["cell"])
				if erased_cells.has(c): continue
				if cell_data.has(c):
					var cd = cell_data[c]
					if cd.get("wall") != null or cd.get("tile") != null: continue
			filtered.append(item)
		room[k] = filtered

static func _prune_room_props(room: Dictionary, _touched: Dictionary, erased_cells: Dictionary, erased_props: Dictionary, cell_data: Dictionary) -> void:
	for k in ["props", "arches", "pillars", "torches"]:
		if not room.has(k) or not (room[k] is Array): continue
		var filtered = []
		for item in room[k]:
			if item is Dictionary and item.has("cell"):
				var c = CastleLevelData.arr_to_vec2i(item["cell"])
				if erased_cells.has(c) or erased_props.has(c): continue
				if cell_data.has(c):
					var cd = cell_data[c]
					if cd.get("prop") != null or cd.get("wall") != null: continue
			filtered.append(item)
		room[k] = filtered

static func _prune_room_spatial_items(room: Dictionary, erased_cells: Dictionary, builder: Node3D) -> void:
	for k in ["carpets", "lights"]:
		if not room.has(k) or not (room[k] is Array): continue
		var filtered = []
		for item in room[k]:
			if item is Dictionary and item.has("pos") and builder:
				var c = builder.world_to_grid(CastleLevelData.arr_to_vec3(item["pos"]))
				if erased_cells.has(c): continue
			filtered.append(item)
		room[k] = filtered

	if room.has("towers") and room["towers"] is Array:
		for t_def in room["towers"]:
			if t_def is Dictionary and t_def.has("tiles") and t_def["tiles"] is Array:
				var filtered_tiles = []
				for t_item in t_def["tiles"]:
					if t_item is Dictionary and t_item.has("cell"):
						var c = CastleLevelData.arr_to_vec2i(t_item["cell"])
						if erased_cells.has(c): continue
					filtered_tiles.append(t_item)
				t_def["tiles"] = filtered_tiles

static func _merge_custom_additions(rooms: Array, custom_additions: Dictionary) -> void:
	var custom_idx = -1
	for i in range(rooms.size()):
		if rooms[i] is Dictionary and rooms[i].get("name") == "EditorCustom":
			custom_idx = i
			break

	var target_room: Dictionary
	if custom_idx >= 0:
		target_room = rooms[custom_idx]
	else:
		target_room = {
			"name": "EditorCustom", "tiles": [], "carpets": [], "pillars": [],
			"torches": [], "arches": [], "props": [], "lights": [], "windows": [], "modular_walls": []
		}
		rooms.append(target_room)

	for key in ["tiles", "modular_walls", "windows", "arches", "props"]:
		if not target_room.has(key) or not (target_room[key] is Array):
			target_room[key] = []
		target_room[key].append_array(custom_additions.get(key, []))
