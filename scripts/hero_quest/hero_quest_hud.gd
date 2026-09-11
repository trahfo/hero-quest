extends CanvasLayer

signal menu_requested

@onready var location_label: Label = $TopBar/Panel/HBox/LocationLabel
@onready var prompt_panel: PanelContainer = $BottomPrompt
@onready var prompt_label: Label = $BottomPrompt/Margin/PromptLabel
@onready var notice_panel: PanelContainer = $CenterNotice
@onready var notice_label: Label = $CenterNotice/Margin/NoticeLabel
@onready var menu_button: Button = $TopBar/MenuButton

var notice_tween: Tween

func _ready() -> void:
	prompt_panel.visible = false
	notice_panel.modulate.a = 0.0
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
