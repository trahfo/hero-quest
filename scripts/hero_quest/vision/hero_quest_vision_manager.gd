class_name HeroQuestVisionManager
extends Node

## High-performance coordinator for Line of Sight calculations, exploration memory,
## dynamic light activation, and Fog of War rendering.

const HeroQuestLosCalculator = preload("res://scripts/hero_quest/vision/hero_quest_los_calculator.gd")
const HeroQuestLightBudget = preload("res://scripts/hero_quest/vision/hero_quest_light_budget.gd")
const HeroQuestFogRenderer = preload("res://scripts/hero_quest/vision/hero_quest_fog_renderer.gd")
const HeroQuestDoor = preload("res://scripts/hero_quest/hero_quest_door.gd")

signal vision_updated(visible_cells: Dictionary, explored_cells: Dictionary)

@export var dark_sight_radius: float = 5.2   # ~50% reduced: 1.4 core + 3.8 soft falloff tiles in dark
@export var torch_sight_radius: float = 7.8  # ~50% reduced: 3.0 core + 4.8 soft falloff tiles around torches
@export var falloff_tiles: float = 3.8       # Soft gradual atmospheric feathering

var builder: Node3D
var player: Node3D
var camera: Camera3D
var fog_renderer: HeroQuestFogRenderer

var explored_cells: Dictionary = {} # Vector2i -> bool
var visible_cells: Dictionary = {}  # Vector2i -> float (intensity)

# Array of Dictionary: { "node": OmniLight3D, "cell": Vector2i, "radius": float, "energy": float }
var registered_lights: Array[Dictionary] = []
var registered_doors: Array[HeroQuestDoor] = []

var is_fog_enabled: bool = true
var _fov_cache: Dictionary = {}    # Vector3i -> Dictionary (per-source FoV, cleared on door/grid change)
var _block_cache: Dictionary = {}  # Vector2i -> bool
var _last_player_tile: Vector2i = Vector2i(-9999, -9999)

func setup(p_builder: Node3D, p_player: Node3D, p_camera: Camera3D) -> void:
	builder = p_builder
	player = p_player
	camera = p_camera

	fog_renderer = HeroQuestFogRenderer.new()
	add_child(fog_renderer)
	fog_renderer.setup(camera)

	if builder and "grid" in builder:
		fog_renderer.update_bounds_from_grid(builder.grid.keys(), 2.0)

	refresh_scene_entities()
	update_vision(true)

func invalidate_caches() -> void:
	_fov_cache.clear()
	_block_cache.clear()

func refresh_scene_entities() -> void:
	invalidate_caches()
	registered_lights.clear()
	registered_doors.clear()

	if not builder or not is_instance_valid(builder):
		return

	# Discover and register all dungeon lights (torches, braziers, candelabras, lamps)
	var all_lights = builder.find_children("*", "OmniLight3D", true, false)
	for l in all_lights:
		var light = l as OmniLight3D
		if not light or not is_instance_valid(light):
			continue
		# Ignore player-attached lantern and dropped floor item glow indicators
		if light.get_parent() and ("HeroBox" in light.get_parent().name or "FloorItem" in light.get_parent().name):
			continue

		var cell = builder.world_to_grid(light.global_position)
		var rad = clampf((light.omni_range / 2.0) + 2.0, 5.0, 8.5) if light.omni_range > 0.0 else torch_sight_radius
		registered_lights.append({
			"node": light,
			"cell": cell,
			"radius": rad,
			"energy": light.light_energy
		})

	# Discover and listen to interactive doors
	var all_doors = builder.find_children("*", "HeroQuestDoor", true, false)
	for d in all_doors:
		var door = d as HeroQuestDoor
		if is_instance_valid(door) and not registered_doors.has(door):
			registered_doors.append(door)
			if not door.door_state_changed.is_connected(_on_door_state_changed):
				door.door_state_changed.connect(_on_door_state_changed)

func _on_door_state_changed(_open: bool, _locked: bool) -> void:
	invalidate_caches()
	update_vision(true)

func is_cell_blocking(cell: Vector2i) -> bool:
	if _block_cache.has(cell):
		return _block_cache[cell]
	var blocked = _compute_blocking(cell)
	_block_cache[cell] = blocked
	return blocked

func _compute_blocking(cell: Vector2i) -> bool:
	if not builder or not is_instance_valid(builder) or not ("grid" in builder) or not builder.grid:
		return false
	if not builder.grid.has(cell):
		return true # Void / outside boundary blocks sight

	var tile_info = builder.grid[cell]
	var t_type = int(tile_info.get("type", 0))

	# Modular walls and window walls block sight
	if t_type == 6:
		return true

	# Check non-walkable tiles (pillars, closed doors, large static barriers)
	var is_walkable = bool(tile_info.get("walkable", true))
	if not is_walkable:
		var prop = tile_info.get("prop", null)
		if is_instance_valid(prop) and prop is HeroQuestDoor:
			return not prop.is_open
		return true

	return false

## Recomputes only when the hero enters a new grid cell (vision is cell-based, so sub-tile
## movement can never change the result), or when forced (door/fog/editor change).
func update_vision(force: bool = false) -> void:
	if not builder or not player or not is_instance_valid(player):
		return

	var p_pos = player.global_position
	var p_cell = builder.world_to_grid(p_pos)
	if not force and p_cell == _last_player_tile:
		return

	_last_player_tile = p_cell
	var is_blocking = Callable(self, "is_cell_blocking")

	# 1. Base Line of Sight from Hero with gentle 3.8-tile soft falloff (cached, shared with step 3)
	var hero_fov = HeroQuestLosCalculator.compute_fov_cached(_fov_cache, p_cell, dark_sight_radius, is_blocking, falloff_tiles)

	# 2. Amplify Line of Sight from nearby illuminated light sources
	var active_sources: Array[Dictionary] = [
		{ "origin": p_cell, "radius": dark_sight_radius, "intensity": 1.0, "falloff_tiles": falloff_tiles }
	]
	var near_cells = ceili(dark_sight_radius) + 1
	var lit_nodes: Array = []

	for light_data in registered_lights:
		var light_node: OmniLight3D = light_data.get("node", null)
		if not is_instance_valid(light_node):
			continue

		var l_cell: Vector2i = light_data["cell"]
		var l_energy: float = light_data["energy"]

		if not is_fog_enabled:
			HeroQuestLightBudget.set_light_active(light_node, true, l_energy)
			lit_nodes.append(light_node)
			continue

		# Cheap bounding box test first: lights outside it are never even ray-traced
		var is_light_visible = false
		if absi(l_cell.x - p_cell.x) <= near_cells and absi(l_cell.y - p_cell.y) <= near_cells:
			is_light_visible = hero_fov.has(l_cell) or HeroQuestLosCalculator.has_clear_los(p_cell, l_cell, is_blocking)

		HeroQuestLightBudget.set_light_active(light_node, is_light_visible, l_energy)
		if is_light_visible:
			lit_nodes.append(light_node)
			active_sources.append({
				"origin": l_cell,
				"radius": light_data["radius"],
				"intensity": 1.0,
				"falloff_tiles": 4.8
			})

	HeroQuestLightBudget.apply_shadow_budget(lit_nodes, p_pos)

	# 3. Compute Composite Visibility Map with smooth gradients (static light FoVs come from cache)
	visible_cells = HeroQuestLosCalculator.compute_multi_source_fov(active_sources, is_blocking, _fov_cache)

	# 4. Update Explored History
	for cell in visible_cells.keys():
		if float(visible_cells[cell]) > 0.05:
			explored_cells[cell] = true

	# 5. Update Fog of War Shroud & Texture
	if fog_renderer:
		fog_renderer.update_fog_map(visible_cells, explored_cells, 2.0)

	vision_updated.emit(visible_cells, explored_cells)

func set_fog_enabled(enabled: bool) -> void:
	is_fog_enabled = enabled
	if fog_renderer:
		fog_renderer.set_enabled(enabled)

	refresh_scene_entities()

	if builder and "grid" in builder and fog_renderer:
		fog_renderer.update_bounds_from_grid(builder.grid.keys(), 2.0)

	update_vision(true)

func toggle_fog() -> void:
	set_fog_enabled(not is_fog_enabled)

func reveal_all() -> void:
	if not builder or not ("grid" in builder):
		return
	for c in builder.grid.keys():
		explored_cells[c] = true
		visible_cells[c] = 1.0
	if fog_renderer:
		fog_renderer.reveal_all()
	var all_nodes: Array = []
	for light_data in registered_lights:
		var light_node: OmniLight3D = light_data.get("node", null)
		if is_instance_valid(light_node):
			HeroQuestLightBudget.set_light_active(light_node, true, light_data.get("energy", 1.0))
			all_nodes.append(light_node)
	HeroQuestLightBudget.apply_shadow_budget(all_nodes, player.global_position if player else Vector3.ZERO)
