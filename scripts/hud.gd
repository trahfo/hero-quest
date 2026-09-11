extends CanvasLayer

signal restart_pressed

@onready var score_label: Label = $TopMargin/TopHBox/ScorePanel/ScoreLabel
@onready var time_label: Label = $TopMargin/TopHBox/TimePanel/TimeLabel
@onready var level_label: Label = $TopMargin/TopHBox/LevelPanel/HBox/LevelLabel
@onready var speed_label: Label = $TopMargin/TopHBox/LevelPanel/HBox/SpeedLabel
@onready var lives_container: HBoxContainer = $TopMargin/TopHBox/LivesPanel/LivesHBox

@onready var level_cleared_panel: PanelContainer = $CenterMargin/LevelClearedPanel
@onready var level_cleared_title: Label = $CenterMargin/LevelClearedPanel/VBox/TitleLabel
@onready var level_cleared_speed: Label = $CenterMargin/LevelClearedPanel/VBox/SpeedDescLabel

@onready var game_over_panel: PanelContainer = $CenterMargin/GameOverPanel
@onready var final_score_label: Label = $CenterMargin/GameOverPanel/VBox/FinalScoreLabel
@onready var final_time_label: Label = $CenterMargin/GameOverPanel/VBox/FinalTimeLabel
@onready var restart_button: Button = $CenterMargin/GameOverPanel/VBox/RestartButton

func _ready() -> void:
	level_cleared_panel.visible = false
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)
	var menu_btn = get_node_or_null("TopMargin/TopHBox/MenuButton")
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_menu_pressed()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func update_score(score: int) -> void:
	score_label.text = "SCORE: %05d" % score

func update_time(seconds: float) -> void:
	var total_sec = int(seconds)
	var mins = floori(total_sec / 60.0)
	var secs = total_sec % 60
	time_label.text = "TIME: %02d:%02d" % [mins, secs]

func update_level(level: int, speed_pct: float) -> void:
	level_label.text = "LEVEL %d" % level
	speed_label.text = "SPEED: %d%%" % int(speed_pct)

func update_lives(lives: int) -> void:
	for child in lives_container.get_children():
		child.queue_free()
	for i in range(lives):
		var lbl = Label.new()
		lbl.text = "🟡"
		lbl.add_theme_font_size_override("font_size", 22)
		lives_container.add_child(lbl)

func show_level_cleared(level: int, speed_pct: float) -> void:
	level_cleared_title.text = "★ LEVEL %d COMPLETE! ★" % level
	level_cleared_speed.text = "SPEED INCREASED BY +10%%!\nCURRENT SPEED: %d%%" % int(speed_pct)
	level_cleared_panel.visible = true

func hide_level_cleared() -> void:
	level_cleared_panel.visible = false

func show_game_over(final_score: int, final_seconds: float) -> void:
	var total_sec = int(final_seconds)
	var mins = floori(total_sec / 60.0)
	var secs = total_sec % 60
	final_score_label.text = "FINAL SCORE: %d" % final_score
	final_time_label.text = "TIME SURVIVED: %02d:%02d" % [mins, secs]
	game_over_panel.visible = true

func hide_game_over() -> void:
	game_over_panel.visible = false

func _on_restart_button_pressed() -> void:
	restart_pressed.emit()
