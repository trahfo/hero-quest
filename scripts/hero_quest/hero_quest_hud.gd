extends CanvasLayer

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const HeroQuestCharacterSheet = preload("res://scripts/hero_quest/hero_quest_character_sheet.gd")
const HeroQuestLootDialog = preload("res://scripts/hero_quest/hero_quest_loot_dialog.gd")

signal menu_requested

@onready var location_label: Label = $TopBar/Panel/HBox/LocationLabel
@onready var prompt_panel: PanelContainer = $BottomPrompt
@onready var prompt_label: Label = $BottomPrompt/Margin/PromptLabel
@onready var notice_panel: PanelContainer = $CenterNotice
@onready var notice_label: Label = $CenterNotice/Margin/NoticeLabel
@onready var menu_button: Button = $TopBar/MenuButton
@onready var hero_sheet_button: Button = $TopBar/HeroSheetButton
@onready var character_sheet: HeroQuestCharacterSheet = $HeroQuestCharacterSheet
@onready var loot_dialog: HeroQuestLootDialog = $HeroQuestLootDialog

var notice_tween: Tween
var current_player: CharacterBody3D = null

func _ready() -> void:
	prompt_panel.visible = false
	notice_panel.modulate.a = 0.0
	menu_button.pressed.connect(_on_menu_pressed)
	if hero_sheet_button:
		hero_sheet_button.pressed.connect(toggle_character_sheet)

func setup_player_ui(player: CharacterBody3D) -> void:
	current_player = player
	if not player:
		return

	if character_sheet and player.inventory and player.stats:
		character_sheet.setup(player.inventory, player.stats)
		character_sheet.item_dropped_to_floor.connect(func(item):
			player.drop_item_to_world(item)
			show_notice("Dropped %s onto the floor" % item.name)
		)
		character_sheet.item_swapped.connect(func(old, new_it, slot):
			show_notice("Swapped %s for %s!" % [old.name, new_it.name])
		)

	if loot_dialog:
		loot_dialog.loot_taken.connect(func(item):
			player.on_loot_collected(item)
			show_notice("Acquired: %s!" % item.name)
		)
		loot_dialog.loot_dropped_to_floor.connect(func(item, pos):
			player.drop_item_to_world(item, pos)
			show_notice("Left %s on the floor" % item.name)
		)

	if not player.open_loot_dialog_requested.is_connected(show_loot_dialog):
		player.open_loot_dialog_requested.connect(show_loot_dialog)
	if not player.toggle_character_sheet_requested.is_connected(toggle_character_sheet):
		player.toggle_character_sheet_requested.connect(toggle_character_sheet)

func toggle_character_sheet() -> void:
	if not character_sheet: return
	character_sheet.visible = not character_sheet.visible
	if character_sheet.visible:
		character_sheet.refresh_ui()

func show_loot_dialog(item: ItemData, drop_pos: Vector3) -> void:
	if not loot_dialog: return
	if character_sheet:
		character_sheet.visible = true
		character_sheet.refresh_ui()
	loot_dialog.open_dialog(item, drop_pos, character_sheet)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C or event.keycode == KEY_I:
			toggle_character_sheet()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if loot_dialog and loot_dialog.visible:
				loot_dialog.close_dialog()
				get_viewport().set_input_as_handled()
				return
			if character_sheet and character_sheet.visible:
				character_sheet.visible = false
				get_viewport().set_input_as_handled()
				return
			_on_menu_pressed()

func _on_menu_pressed() -> void:
	menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func update_location(zone_name: String) -> void:
	if location_label:
		location_label.text = "⚔️  " + zone_name.to_upper()

func show_prompt(text: String) -> void:
	if prompt_panel and prompt_label:
		if text == "":
			prompt_panel.visible = false
		else:
			prompt_label.text = text
			prompt_panel.visible = true

func show_notice(text: String) -> void:
	if not notice_panel or not notice_label:
		return

	notice_label.text = text
	if notice_tween and notice_tween.is_valid():
		notice_tween.kill()

	notice_tween = create_tween()
	notice_panel.scale = Vector2(0.9, 0.9)
	notice_tween.parallel().tween_property(notice_panel, "modulate:a", 1.0, 0.2)
	notice_tween.parallel().tween_property(notice_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	notice_tween.tween_interval(2.5)
	notice_tween.tween_property(notice_panel, "modulate:a", 0.0, 0.5)
