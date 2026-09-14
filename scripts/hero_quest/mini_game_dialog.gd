class_name HeroQuestMiniGameDialog
extends CanvasLayer

const MiniGameManager = preload("res://scripts/hero_quest/mini_game_manager.gd")

## Modal dialog shown when discovering or interacting with a Mini-Game Easter Egg.

signal play_requested(game_id: String)
signal closed

var panel: PanelContainer
var title_lbl: Label
var name_lbl: Label
var desc_lbl: Label
var icon_lbl: Label
var play_btn: Button
var close_btn: Button

var current_game_id: String = ""

func _init() -> void:
	layer = 25
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.02, 0.03, 0.06, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 420)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.14, 0.98)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(1.0, 0.82, 0.2, 1.0) # Golden arcade border
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.shadow_color = Color(0.9, 0.7, 0.1, 0.35)
	sb.shadow_size = 28
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	icon_lbl = Label.new()
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 46)
	icon_lbl.text = "🟡 👻"
	vbox.add_child(icon_lbl)

	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.text = "✨ SECRET EASTER EGG DISCOVERED! ✨"
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_lbl)

	name_lbl = Label.new()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text = "PAC-MAN 3D"
	name_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_lbl)

	desc_lbl = Label.new()
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text = "Within this ancient ironbound chest, you uncover a glowing neon relic of an alternate realm! Will you step into the labyrinth?"
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.9))
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_box)

	play_btn = Button.new()
	play_btn.text = "▶️  PLAY MINI-GAME NOW"
	play_btn.custom_minimum_size = Vector2(0, 52)
	play_btn.add_theme_font_size_override("font_size", 18)
	var play_sb = StyleBoxFlat.new()
	play_sb.bg_color = Color(0.1, 0.45, 0.9, 1.0)
	play_sb.border_width_left = 2
	play_sb.border_width_top = 2
	play_sb.border_width_right = 2
	play_sb.border_width_bottom = 2
	play_sb.border_color = Color(0.5, 0.9, 1.0, 1.0)
	play_sb.corner_radius_top_left = 6
	play_sb.corner_radius_top_right = 6
	play_sb.corner_radius_bottom_right = 6
	play_sb.corner_radius_bottom_left = 6
	play_btn.add_theme_stylebox_override("normal", play_sb)
	play_btn.pressed.connect(_on_play_pressed)
	btn_box.add_child(play_btn)

	close_btn = Button.new()
	close_btn.text = "🎒  KEEP ADVENTURING"
	close_btn.custom_minimum_size = Vector2(0, 44)
	close_btn.add_theme_font_size_override("font_size", 15)
	var close_sb = StyleBoxFlat.new()
	close_sb.bg_color = Color(0.18, 0.2, 0.25, 0.8)
	close_sb.border_width_left = 1
	close_sb.border_width_top = 1
	close_sb.border_width_right = 1
	close_sb.border_width_bottom = 1
	close_sb.border_color = Color(0.4, 0.45, 0.5, 0.8)
	close_sb.corner_radius_top_left = 6
	close_sb.corner_radius_top_right = 6
	close_sb.corner_radius_bottom_right = 6
	close_sb.corner_radius_bottom_left = 6
	close_btn.add_theme_stylebox_override("normal", close_sb)
	close_btn.pressed.connect(_on_close_pressed)
	btn_box.add_child(close_btn)

	visible = false

func show_dialog(game_id: String, game_info: Dictionary = {}) -> void:
	current_game_id = game_id
	if game_info.is_empty() and ClassDB.class_exists("MiniGameManager"):
		game_info = MiniGameManager.get_mini_game(game_id)

	if not game_info.is_empty():
		name_lbl.text = game_info.get("title", game_id.to_upper())
		icon_lbl.text = game_info.get("icon", "🕹️")
		if game_info.has("description"):
			desc_lbl.text = game_info["description"]
	visible = true

func _on_play_pressed() -> void:
	visible = false
	play_requested.emit(current_game_id)

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
