extends Control

const HeroQuestGame = preload("res://scripts/hero_quest/hero_quest_game.gd")
const HeroQuestLevelManagerClass = preload("res://scripts/hero_quest/level/hero_quest_level_manager.gd")

@onready var hero_card: PanelContainer = $CenterContainer/HeroCard
@onready var levels_vbox: VBoxContainer = $CenterContainer/HeroCard/Margin/VBox/LevelsVBox
@onready var prev_btn: Button = $CenterContainer/HeroCard/Margin/VBox/PaginationHBox/PrevButton
@onready var page_label: Label = $CenterContainer/HeroCard/Margin/VBox/PaginationHBox/PageLabel
@onready var next_btn: Button = $CenterContainer/HeroCard/Margin/VBox/PaginationHBox/NextButton
@onready var new_level_btn: Button = $CenterContainer/HeroCard/Margin/VBox/NewLevelButton
@onready var quit_btn: Button = $BottomBar/QuitButton

@onready var modal: PanelContainer = $NewLevelModal
@onready var level_name_input: LineEdit = $NewLevelModal/Center/Card/Margin/VBox/LevelNameInput
@onready var create_btn: Button = $NewLevelModal/Center/Card/Margin/VBox/ButtonsHBox/CreateButton
@onready var cancel_modal_btn: Button = $NewLevelModal/Center/Card/Margin/VBox/ButtonsHBox/CancelButton

var level_buttons: Array[Button] = []
var all_levels: Array[Dictionary] = []
var page_levels: Array[Dictionary] = []
var current_page: int = 0
var total_pages: int = 1

var audio_player: AudioStreamPlayer
var sfx_click: AudioStreamWAV
var sfx_hover: AudioStreamWAV

func _ready() -> void:
	_setup_audio()
	_collect_level_buttons()
	_connect_signals()
	refresh_levels()

func _collect_level_buttons() -> void:
	level_buttons.clear()
	for i in range(1, 6):
		var btn = levels_vbox.get_node_or_null("LevelButton%d" % i) as Button
		if btn:
			level_buttons.append(btn)
			var idx = i - 1
			btn.pressed.connect(func(): _on_level_clicked(idx))
			btn.mouse_entered.connect(_play_hover_sound)

func _connect_signals() -> void:
	prev_btn.pressed.connect(_on_prev_page_pressed)
	next_btn.pressed.connect(_on_next_page_pressed)
	prev_btn.mouse_entered.connect(_play_hover_sound)
	next_btn.mouse_entered.connect(_play_hover_sound)

	new_level_btn.pressed.connect(_on_new_level_pressed)
	new_level_btn.mouse_entered.connect(_play_hover_sound)
	quit_btn.pressed.connect(_on_quit_pressed)

	if create_btn:
		create_btn.pressed.connect(_on_create_confirmed)
	if cancel_modal_btn:
		cancel_modal_btn.pressed.connect(_on_cancel_modal_pressed)
	if level_name_input:
		level_name_input.text_submitted.connect(func(_t): _on_create_confirmed())

func refresh_levels() -> void:
	all_levels = HeroQuestLevelManagerClass.get_available_levels()
	total_pages = HeroQuestLevelManagerClass.get_total_pages(all_levels.size(), HeroQuestLevelManagerClass.PAGE_SIZE)
	current_page = clampi(current_page, 0, total_pages - 1)
	_render_page()

func _render_page() -> void:
	page_levels = HeroQuestLevelManagerClass.get_levels_page(all_levels, current_page, HeroQuestLevelManagerClass.PAGE_SIZE)
	page_label.text = "Page %d of %d" % [current_page + 1, total_pages]

	prev_btn.disabled = (current_page <= 0)
	next_btn.disabled = (current_page >= total_pages - 1)

	for i in range(level_buttons.size()):
		var btn = level_buttons[i]
		if i < page_levels.size():
			btn.visible = true
			var lvl = page_levels[i]
			btn.text = "🏰  " + lvl.name
			btn.tooltip_text = "%s (%d rooms · %d tiles)" % [lvl.file_name, lvl.rooms_count, lvl.tiles_count]
		else:
			btn.visible = false

func _on_level_clicked(idx: int) -> void:
	if idx < page_levels.size():
		var chosen = page_levels[idx]
		HeroQuestGame.selected_level_path = chosen.file_path
		HeroQuestGame.pending_level_name = chosen.name
		HeroQuestGame.start_in_edit_mode = false
		_play_click_and_launch("res://scenes/hero_quest.tscn")

func _on_prev_page_pressed() -> void:
	if current_page > 0:
		_play_click_sound()
		current_page -= 1
		_render_page()

func _on_next_page_pressed() -> void:
	if current_page < total_pages - 1:
		_play_click_sound()
		current_page += 1
		_render_page()

func _on_new_level_pressed() -> void:
	_play_click_sound()
	if modal:
		modal.visible = true
		if level_name_input:
			level_name_input.text = "Custom Level %d" % (all_levels.size() + 1)
			level_name_input.grab_focus()
			level_name_input.select_all()

func _on_create_confirmed() -> void:
	var raw_name = level_name_input.text.strip_edges() if level_name_input else ""
	if raw_name == "":
		raw_name = "Untitled Level"

	var target_path = HeroQuestLevelManagerClass.generate_new_level_path(raw_name)
	HeroQuestGame.selected_level_path = target_path
	HeroQuestGame.pending_level_name = raw_name
	HeroQuestGame.start_in_edit_mode = true

	_play_click_and_launch("res://scenes/hero_quest.tscn")

func _on_cancel_modal_pressed() -> void:
	_play_click_sound()
	if modal:
		modal.visible = false

func _play_click_and_launch(scene_path: String) -> void:
	_play_click_sound()
	get_tree().change_scene_to_file(scene_path)

func _play_click_sound() -> void:
	if audio_player and sfx_click:
		audio_player.stream = sfx_click
		audio_player.volume_db = -4.0
		audio_player.play()

func _play_hover_sound() -> void:
	if audio_player and sfx_hover:
		audio_player.stream = sfx_hover
		audio_player.volume_db = -10.0
		audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if modal and modal.visible:
			_on_cancel_modal_pressed()
			get_viewport().set_input_as_handled()
		else:
			_on_quit_pressed()
			get_viewport().set_input_as_handled()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)

	sfx_click = _generate_tone(523.25, 659.25, 0.12)
	sfx_hover = _generate_tone(440.0, 554.37, 0.06)

func _generate_tone(f1: float, f2: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var p1: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(f1, f2, t)
		p1 += 2.0 * PI * freq / sample_rate
		var env = 1.0 - pow(t, 2.0)
		var val = sin(p1) * env * 0.4
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
