class_name TestSuiteVisionPerformance
extends RefCounted

const HeroQuestFogRenderer = preload("res://scripts/hero_quest/vision/hero_quest_fog_renderer.gd")
const HeroQuestLosCalculator = preload("res://scripts/hero_quest/vision/hero_quest_los_calculator.gd")
const HeroQuestLightBudget = preload("res://scripts/hero_quest/vision/hero_quest_light_budget.gd")

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 10] VISION PERFORMANCE: FOG TEXTURE, FOV CACHE & LIGHT BUDGET ===")

	# --- Fog texture: 1 texel per grid cell, correct UV mapping, dirty-only upload ---
	print("\n[TEST V1] Verifying 1-texel-per-cell fog mapping and differential updates...")
	var fog = HeroQuestFogRenderer.new()
	tree.root.add_child(fog)
	fog.setup(null)
	var cells: Array = []
	for x in range(-5, 11):
		for y in range(-3, 8):
			cells.append(Vector2i(x, y))
	fog.update_bounds_from_grid(cells, 2.0)
	assert(fog.texture_width == 16 + 8 and fog.texture_height == 11 + 8, "texture sized to grid + margin")
	assert(fog.min_cell == Vector2i(-9, -7))
	# UV of a cell centre must land in the middle of that cell's texel
	var cell = Vector2i(3, 2)
	var uv = (Vector2(cell) * 2.0 - fog.world_min) / fog.world_size
	var px = Vector2i(int(uv.x * fog.texture_width), int(uv.y * fog.texture_height))
	assert(px == fog.cell_to_pixel(cell), "UV mapping hits the cell's own texel")

	var visible = {cell: 0.75}
	var explored = {cell: true}
	fog.update_fog_map(visible, explored, 2.0)
	var c = fog.fow_image.get_pixelv(fog.cell_to_pixel(cell))
	assert(absf(c.r - 0.75) < 0.01 and absf(c.g - 1.0) < 0.01, "RGBA8 quantised stamp")
	fog.update_fog_map({}, explored, 2.0)
	c = fog.fow_image.get_pixelv(fog.cell_to_pixel(cell))
	assert(is_equal_approx(c.r, 0.0) and is_equal_approx(c.g, 1.0), "explored memory persists, visibility clears")
	assert(not fog._dirty, "texture uploaded and dirty flag cleared")
	fog.update_fog_map({}, explored, 2.0)
	assert(not fog._dirty, "no-op update stays clean")
	var tex_before = fog.fow_texture
	fog.update_bounds_from_grid(cells, 2.0)
	assert(fog.fow_texture == tex_before, "unchanged bounds do not rebuild the texture")
	fog.update_fog_map({Vector2i(9999, 9999): 1.0}, {}, 2.0)
	fog.queue_free()

	# --- FoV cache ---
	print("\n[TEST V2] Verifying per-source FoV caching...")
	var calls = [0]
	var blocker = func(cell: Vector2i) -> bool:
		calls[0] += 1
		return cell.x == 3
	var cache: Dictionary = {}
	var a = HeroQuestLosCalculator.compute_fov_cached(cache, Vector2i.ZERO, 6.0, blocker, 3.0)
	var first_calls = calls[0]
	assert(first_calls > 0 and cache.size() == 1)
	var b = HeroQuestLosCalculator.compute_fov_cached(cache, Vector2i.ZERO, 6.0, blocker, 3.0)
	assert(calls[0] == first_calls and a == b, "second lookup is served from cache")
	assert(not a.has(Vector2i(5, 0)), "wall at x=3 blocks cells behind it")
	var composite = HeroQuestLosCalculator.compute_multi_source_fov([
		{"origin": Vector2i.ZERO, "radius": 6.0, "intensity": 1.0, "falloff_tiles": 3.0}
	], blocker, cache)
	assert(calls[0] == first_calls and composite.size() == a.size(), "composite reuses cached source")

	# --- Light budget ---
	print("\n[TEST V3] Verifying shadow budget and flicker-timer pausing...")
	var root = Node3D.new()
	tree.root.add_child(root)
	var lights: Array = []
	for i in range(8):
		var l = OmniLight3D.new()
		l.shadow_enabled = true
		l.position = Vector3(i * 3.0, 0, 0)
		var t = Timer.new()
		l.add_child(t)
		root.add_child(l)
		t.start(0.1)
		lights.append(l)
	HeroQuestLightBudget.apply_shadow_budget(lights, Vector3.ZERO)
	assert(HeroQuestLightBudget.count_shadow_lights(lights) == HeroQuestLightBudget.MAX_SHADOW_LIGHTS)
	for i in range(HeroQuestLightBudget.MAX_SHADOW_LIGHTS):
		assert(lights[i].shadow_enabled, "nearest lights keep shadows")
	assert(not lights[7].shadow_enabled, "far lights lose shadows")
	HeroQuestLightBudget.set_light_active(lights[0], false, 1.0)
	assert(not lights[0].visible and lights[0].get_child(0).paused, "hidden light pauses its flicker timer")
	HeroQuestLightBudget.set_light_active(lights[0], true, 1.0)
	assert(lights[0].visible and not lights[0].get_child(0).paused)
	root.queue_free()
	print("  ✓ Vision performance tests passed")
