class_name HeroQuestLightBudget
extends RefCounted

## Keeps dynamic lighting cheap: hidden lights pause their flicker timers and only the
## nearest few active omni lights keep expensive cube/paraboloid shadow maps.

const MAX_SHADOW_LIGHTS: int = 4

## Toggles a light only when its state really changes (avoids renderer churn) and
## pauses/resumes its flicker Timer child. Flicker keeps running between toggles.
static func set_light_active(light: OmniLight3D, active: bool, energy: float) -> void:
	if light.visible == active:
		return
	light.visible = active
	if active:
		light.light_energy = energy
	for child in light.get_children():
		if child is Timer:
			child.paused = not active

## Enables shadows on the `max_shadows` visible lights closest to `origin`, disables the rest.
static func apply_shadow_budget(lights: Array, origin: Vector3, max_shadows: int = MAX_SHADOW_LIGHTS) -> void:
	var ranked: Array = []
	for l in lights:
		var light = l as OmniLight3D
		if is_instance_valid(light) and light.visible:
			ranked.append([light.global_position.distance_squared_to(origin), light])
		elif is_instance_valid(light) and light.shadow_enabled:
			light.shadow_enabled = false
	ranked.sort_custom(func(a, b): return a[0] < b[0])
	for i in range(ranked.size()):
		var want = i < max_shadows
		var light: OmniLight3D = ranked[i][1]
		if light.shadow_enabled != want:
			light.shadow_enabled = want

static func count_shadow_lights(lights: Array) -> int:
	var n = 0
	for l in lights:
		if is_instance_valid(l) and l.visible and l.shadow_enabled:
			n += 1
	return n
