extends Node

var chomp_toggle: bool = false
var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

var stream_chomp_a: AudioStreamWAV
var stream_chomp_b: AudioStreamWAV
var stream_level_clear: AudioStreamWAV
var stream_death: AudioStreamWAV

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)

	stream_chomp_a = _generate_tone_sweep(350.0, 600.0, 0.07, 0.4, false)
	stream_chomp_b = _generate_tone_sweep(600.0, 280.0, 0.07, 0.4, false)
	stream_level_clear = _generate_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.12, 0.5)
	stream_death = _generate_tone_sweep(700.0, 120.0, 0.4, 0.5, true)

func _get_free_player() -> AudioStreamPlayer:
	for p in audio_players:
		if not p.playing:
			return p
	return audio_players[0]

func play_chomp() -> void:
	var p = _get_free_player()
	p.stream = stream_chomp_a if chomp_toggle else stream_chomp_b
	chomp_toggle = !chomp_toggle
	p.play()

func play_level_clear() -> void:
	var p = _get_free_player()
	p.stream = stream_level_clear
	p.play()

func play_death() -> void:
	var p = _get_free_player()
	p.stream = stream_death
	p.play()

func _generate_tone_sweep(f_start: float, f_end: float, duration: float, volume: float, noise_blend: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(f_start, f_end, t)
		phase += 2.0 * PI * freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI
		
		var sample_val = sin(phase)
		if noise_blend:
			sample_val = lerpf(sample_val, randf_range(-1.0, 1.0), 0.3)
			
		var env = 1.0 - t
		var val_int = int(clampf(sample_val * env * volume, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, val_int)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_array
	return stream

func _generate_arpeggio(freqs: Array[float], note_duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples_per_note = int(sample_rate * note_duration)
	var total_samples = samples_per_note * freqs.size()
	var byte_array = PackedByteArray()
	byte_array.resize(total_samples * 2)

	for note_idx in range(freqs.size()):
		var freq = freqs[note_idx]
		var phase: float = 0.0
		var base_offset = note_idx * samples_per_note
		for i in range(samples_per_note):
			var t = float(i) / float(samples_per_note)
			phase += 2.0 * PI * freq / float(sample_rate)
			if phase > 2.0 * PI:
				phase -= 2.0 * PI
			var sample_val = sin(phase) + 0.3 * sin(phase * 2.0)
			var env = 1.0 - pow(t, 1.5)
			var val_int = int(clampf(sample_val * env * volume * 0.7, -1.0, 1.0) * 32767.0)
			byte_array.encode_s16((base_offset + i) * 2, val_int)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_array
	return stream
