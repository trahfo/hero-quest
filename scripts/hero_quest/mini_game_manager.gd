class_name MiniGameManager
extends RefCounted

## Global registry and transition coordinator for Hero Quest mini-games.
## Manages game definitions, event hooks, and seamless return to castle state.

static var _registry: Dictionary = {
	"pacman": {
		"id": "pacman",
		"title": "PAC-MAN 3D",
		"tagline": "Neon Arcade Labyrinth",
		"description": "An enchanted relic displaying a labyrinth of glowing yellow dots and colorful spirits.",
		"icon": "🟡👻",
		"scene_path": "res://mini-games/pacman/pacman_game.tscn",
		"relic_name": "Arcane Arcade Relic: Pac-Man 3D"
	}
}

# Return state saved when jumping from Hero Quest into a mini-game
static var active_game_id: String = ""
static var return_scene_path: String = "res://scenes/hero_quest.tscn"
static var saved_player_tile: Vector2i = Vector2i.ZERO
static var saved_level_path: String = "res://data/levels/first_level.json"
static var has_return_state: bool = false
static var is_launched_from_hero_quest: bool = false

# Event listeners: Dictionary of event_name -> Array[Callable]
static var _event_listeners: Dictionary = {}

static func register_mini_game(id: String, info: Dictionary) -> void:
	_registry[id] = info

static func unregister_mini_game(id: String) -> void:
	_registry.erase(id)

static func get_mini_game(id: String) -> Dictionary:
	return _registry.get(id, {})

static func has_mini_game(id: String) -> bool:
	return _registry.has(id)

static func get_all_mini_games() -> Dictionary:
	return _registry

## Connect a callback to a world event (e.g. "chest_opened", "altar_activated")
static func subscribe_event(event_name: String, callback: Callable) -> void:
	if not _event_listeners.has(event_name):
		_event_listeners[event_name] = []
	_event_listeners[event_name].append(callback)

## Trigger an event across all subscribers
static func trigger_event(event_name: String, event_data: Dictionary = {}) -> void:
	if _event_listeners.has(event_name):
		for callback in _event_listeners[event_name]:
			if callback is Callable:
				callback.call(event_data)

## Saves Hero Quest world state and switches scene to the target mini-game
static func launch_mini_game(
	tree: SceneTree,
	game_id: String,
	current_player_tile: Vector2i = Vector2i.ZERO,
	level_path: String = "res://data/levels/first_level.json",
	return_scene: String = "res://scenes/hero_quest.tscn"
) -> bool:
	if not _registry.has(game_id):
		push_error("MiniGameManager: Game '%s' is not registered." % game_id)
		return false

	var game_info = _registry[game_id]
	var scene_path = game_info.get("scene_path", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_error("MiniGameManager: Scene '%s' not found for '%s'." % [scene_path, game_id])
		return false

	active_game_id = game_id
	return_scene_path = return_scene
	saved_player_tile = current_player_tile
	saved_level_path = level_path
	has_return_state = true
	is_launched_from_hero_quest = true

	tree.change_scene_to_file(scene_path)
	return true

## Returns to Hero Quest, restoring saved state
static func return_to_hero_quest(tree: SceneTree) -> void:
	if has_return_state and return_scene_path != "":
		var target = return_scene_path
		# Preserve has_return_state so HeroQuestGame._ready can read saved_player_tile
		tree.change_scene_to_file(target)
	else:
		tree.change_scene_to_file("res://scenes/start_menu.tscn")

## Called by HeroQuestGame on startup to consume saved state if returning
static func consume_return_state() -> Dictionary:
	var state = {
		"has_state": has_return_state,
		"player_tile": saved_player_tile,
		"level_path": saved_level_path,
		"last_game_id": active_game_id
	}
	has_return_state = false
	is_launched_from_hero_quest = false
	active_game_id = ""
	return state
