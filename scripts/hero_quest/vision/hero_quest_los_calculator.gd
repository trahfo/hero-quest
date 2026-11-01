class_name HeroQuestLosCalculator
extends RefCounted

## Pure-computation engine for 2D grid Line of Sight (LoS) and Field of View (FoV).
## Optimized with quadratic gentle atmospheric falloff curves and fast ray tracing.

## Computes visible cells and their illumination intensity from a single origin.
## - origin: Grid cell where the sight or light originates (Vector2i).
## - radius: Maximum reach in grid tiles (float).
## - is_blocking_fn: Callable(cell: Vector2i) -> bool returning true if the cell blocks sight.
## - falloff_tiles: Number of outer tiles over which intensity softly feathers to 0.0.
## Returns Dictionary: Vector2i -> float (intensity between 0.0 and 1.0).
static func compute_fov(origin: Vector2i, radius: float, is_blocking_fn: Callable, falloff_tiles: float = 4.0) -> Dictionary:
	var visible_map: Dictionary = {}
	var rad_int: int = ceili(radius)
	var rad_sq: float = radius * radius
	var core_radius: float = maxf(1.0, radius - falloff_tiles)

	# Origin cell is always fully visible
	visible_map[origin] = 1.0

	for dx in range(-rad_int, rad_int + 1):
		for dz in range(-rad_int, rad_int + 1):
			if dx == 0 and dz == 0:
				continue
			var dist_sq = float(dx * dx + dz * dz)
			if dist_sq > rad_sq:
				continue

			var target_cell = Vector2i(origin.x + dx, origin.y + dz)
			var dist = sqrt(dist_sq)

			# Gentle quadratic gradual falloff for soft atmospheric vignette
			var intensity: float = 1.0
			if dist <= core_radius:
				intensity = 1.0 - (dist / core_radius) * 0.12
			else:
				var u = clampf((dist - core_radius) / (radius - core_radius), 0.0, 1.0)
				# Smooth quadratic ease-out decay
				var decay = (1.0 - u) * (1.0 - u)
				intensity = 0.88 * decay

			if intensity > 0.005 and _trace_ray(origin, target_cell, is_blocking_fn):
				visible_map[target_cell] = intensity

	return visible_map

## Computes composite visibility from multiple light and sight sources.
static func compute_multi_source_fov(sources: Array, is_blocking_fn: Callable) -> Dictionary:
	var composite: Dictionary = {}
	for src in sources:
		var origin: Vector2i = src.get("origin", Vector2i.ZERO)
		var radius: float = float(src.get("radius", 5.5))
		var mult: float = float(src.get("intensity", 1.0))
		var falloff: float = float(src.get("falloff_tiles", 4.0))
		var fov = compute_fov(origin, radius, is_blocking_fn, falloff)

		for cell in fov.keys():
			var val = fov[cell] * mult
			if not composite.has(cell) or val > composite[cell]:
				composite[cell] = val

	return composite

## Fast discrete ray tracing from origin to target.
static func _trace_ray(p0: Vector2i, p1: Vector2i, is_blocking_fn: Callable) -> bool:
	var dx = p1.x - p0.x
	var dy = p1.y - p0.y
	var steps = maxi(absi(dx), absi(dy))
	if steps == 0:
		return true

	var prev_cell = p0

	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var curr_cell = Vector2i(
			roundi(float(p0.x) + float(dx) * t),
			roundi(float(p0.y) + float(dy) * t)
		)

		# Check diagonal leak between two corner obstacles
		if curr_cell.x != prev_cell.x and curr_cell.y != prev_cell.y:
			var corner1 = Vector2i(curr_cell.x, prev_cell.y)
			var corner2 = Vector2i(prev_cell.x, curr_cell.y)
			if is_blocking_fn.call(corner1) and is_blocking_fn.call(corner2):
				return false

		# If an intermediate cell blocks sight before the target, ray is occluded
		if i < steps and is_blocking_fn.call(curr_cell):
			return false

		prev_cell = curr_cell

	return true

## Checks if there is an unobstructed direct line of sight between two arbitrary points.
static func has_clear_los(from_cell: Vector2i, to_cell: Vector2i, is_blocking_fn: Callable) -> bool:
	return _trace_ray(from_cell, to_cell, is_blocking_fn)
