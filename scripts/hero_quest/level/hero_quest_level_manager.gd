class_name HeroQuestLevelManager
extends RefCounted

## Manages discovering, loading metadata, paginating, and generating paths for Hero Quest levels.

const LEVELS_DIR: String = "res://data/levels/"
const PAGE_SIZE: int = 5

## Returns all available level entries sorted with first_level.json prioritized at top.
static func get_available_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	var dir = DirAccess.open(LEVELS_DIR)
	if not dir:
		push_warning("HeroQuestLevelManager: Unable to open levels directory: " + LEVELS_DIR)
		return levels

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json") and not file_name.begins_with("test_"):
			var full_path = LEVELS_DIR.path_join(file_name)
			var meta = _read_level_metadata(full_path, file_name)
			if not meta.is_empty():
				levels.append(meta)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort: first_level.json is always first, then alphabetical by level name
	levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.file_name == "first_level.json":
			return true
		if b.file_name == "first_level.json":
			return false
		return a.name.nocasecmp_to(b.name) < 0
	)

	return levels

## Reads header metadata without parsing entire massive mesh geometries.
static func _read_level_metadata(full_path: String, file_name: String) -> Dictionary:
	var file = FileAccess.open(full_path, FileAccess.READ)
	if not file:
		return {}

	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}

	var lvl_id: String = str(parsed.get("level_id", file_name.get_basename()))
	var lvl_name: String = str(parsed.get("name", file_name.get_basename().capitalize()))
	var rooms: Array = parsed.get("rooms", [])

	var total_tiles: int = 0
	for r in rooms:
		if r is Dictionary and r.has("tiles"):
			total_tiles += (r["tiles"] as Array).size()

	return {
		"file_name": file_name,
		"file_path": full_path,
		"level_id": lvl_id,
		"name": lvl_name,
		"rooms_count": rooms.size(),
		"tiles_count": total_tiles
	}

## Calculates total pages based on available levels count.
static func get_total_pages(levels_count: int, page_size: int = PAGE_SIZE) -> int:
	if levels_count <= 0:
		return 1
	return maxi(1, ceili(float(levels_count) / float(page_size)))

## Returns the slice of levels for a specific 0-based page index.
static func get_levels_page(all_levels: Array[Dictionary], page_index: int, page_size: int = PAGE_SIZE) -> Array[Dictionary]:
	var start_idx = page_index * page_size
	if start_idx >= all_levels.size():
		return []
	var end_idx = mini(start_idx + page_size, all_levels.size())
	return all_levels.slice(start_idx, end_idx)

## Generates a unique, sanitized file path for a newly created level.
static func generate_new_level_path(level_name: String) -> String:
	var base_slug = _sanitize_filename(level_name)
	if base_slug == "":
		base_slug = "custom_level"

	var candidate = LEVELS_DIR.path_join(base_slug + ".json")
	if not FileAccess.file_exists(candidate):
		return candidate

	var idx = 2
	while true:
		candidate = LEVELS_DIR.path_join("%s_%d.json" % [base_slug, idx])
		if not FileAccess.file_exists(candidate):
			return candidate
		idx += 1

	return candidate

static func _sanitize_filename(raw_name: String) -> String:
	var clean = raw_name.strip_edges().to_lower()
	var result = ""
	for i in range(clean.length()):
		var c = clean[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			result += c
		elif c == " " or c == "-" or c == "_":
			if not result.ends_with("_"):
				result += "_"
	return result.strip_edges()
