extends Control

@onready var pacman_card: PanelContainer = $CenterContainer/HBox/PacmanCard
@onready var hero_card: PanelContainer = $CenterContainer/HBox/HeroCard
@onready var play_pacman_btn: Button = $CenterContainer/HBox/PacmanCard/Margin/VBox/PlayPacmanButton
@onready var play_hero_btn: Button = $CenterContainer/HBox/HeroCard/Margin/VBox/PlayHeroButton
@onready var quit_btn: Button = $BottomBar/QuitButton

var audio_player: AudioStreamPlayer
var sfx_click: AudioStreamWAV
var sfx_hover: AudioStreamWAV

func _ready() -> void:
	play_pacman_btn.pressed.connect(_on_play_pacman_pressed)
	play_hero_btn.pressed.connect(_on_play_hero_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	play_pacman_btn.mouse_entered.connect(func(): _on_hover(pacman_card))
	play_pacman_btn.mouse_exited.connect(func(): _on_unhover(pacman_card))

	play_hero_btn.mouse_entered.connect(func(): _on_hover(hero_card))
	play_hero_btn.mouse_exited.connect(func(): _on_unhover(hero_card))

	_setup_audio()

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)

	sfx_click = _generate_tone(523.25, 659.25, 0.12)
	sfx_hover = _generate_tone(440.0, 554.37, 0.06)

func _on_hover(card: PanelContainer) -> void:
	if audio_player and sfx_hover:
		audio_player.stream = sfx_hover
		audio_player.volume_db = -10.0
		audio_player.play()
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.04, 1.04), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_unhover(card: PanelContainer) -> void:
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_play_pacman_pressed() -> void:
	_play_click_and_launch("res://scenes/main.tscn")

func _on_play_hero_pressed() -> void:
	_play_click_and_launch("res://scenes/hero_quest.tscn")

func _play_click_and_launch(scene_path: String) -> void:
	if audio_player and sfx_click:
		audio_player.stream = sfx_click
		audio_player.volume_db = -4.0
		audio_player.play()
	get_tree().change_scene_to_file(scene_path)

func _on_quit_pressed() -> void:
	get_tree().quit()

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
