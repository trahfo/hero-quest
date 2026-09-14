extends Node

const HeroQuestAudioSynth = preload("res://scripts/hero_quest/hero_quest_audio_synth.gd")

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

var stream_dark_music: AudioStreamWAV
var stream_footstep: AudioStreamWAV
var stream_chest_open: AudioStreamWAV
var stream_anvil_clink: AudioStreamWAV
var stream_chapel_bell: AudioStreamWAV
var stream_ui_click: AudioStreamWAV
var stream_door_open: AudioStreamWAV
var stream_door_close: AudioStreamWAV
var stream_door_unlock: AudioStreamWAV
var stream_door_locked: AudioStreamWAV
var stream_portcullis: AudioStreamWAV

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Master"
	music_player.volume_db = -4.0
	add_child(music_player)

	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		sfx_players.append(p)

	_generate_all_audio()
	play_music()

func _generate_all_audio() -> void:
	stream_dark_music = HeroQuestAudioSynth.generate_dark_adventure_music()
	stream_footstep = HeroQuestAudioSynth.generate_footstep()
	stream_chest_open = HeroQuestAudioSynth.generate_chest_open()
	stream_anvil_clink = HeroQuestAudioSynth.generate_anvil_clink()
	stream_chapel_bell = HeroQuestAudioSynth.generate_chapel_bell()
	stream_ui_click = HeroQuestAudioSynth.generate_ui_click()
	stream_door_open = HeroQuestAudioSynth.generate_door_open()
	stream_door_close = HeroQuestAudioSynth.generate_door_close()
	stream_door_unlock = HeroQuestAudioSynth.generate_door_unlock()
	stream_door_locked = HeroQuestAudioSynth.generate_door_locked()
	stream_portcullis = HeroQuestAudioSynth.generate_portcullis()

func play_music() -> void:
	if stream_dark_music:
		music_player.stream = stream_dark_music
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func play_footstep() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_footstep
	p.pitch_scale = randf_range(0.9, 1.15)
	p.volume_db = -12.0
	p.play()

func play_chest() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_chest_open
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -2.0
	p.play()

func play_anvil() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_anvil_clink
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -3.0
	p.play()

func play_chapel_bell() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_chapel_bell
	p.pitch_scale = randf_range(0.98, 1.02)
	p.volume_db = -2.0
	p.play()

func play_ui() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_ui_click
	p.pitch_scale = 1.0
	p.volume_db = -6.0
	p.play()

func play_door_open() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_door_open
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -3.0
	p.play()

func play_door_close() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_door_close
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -2.0
	p.play()

func play_door_unlock() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_door_unlock
	p.pitch_scale = randf_range(0.98, 1.02)
	p.volume_db = -2.0
	p.play()

func play_door_locked() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_door_locked
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -2.0
	p.play()

func play_portcullis() -> void:
	var p = _get_free_sfx_player()
	p.stream = stream_portcullis
	p.pitch_scale = randf_range(0.95, 1.05)
	p.volume_db = -3.0
	p.play()

