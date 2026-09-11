class_name HeroQuestAudioSynth
extends RefCounted

## Procedural audio waveform synthesis for Hero Quest (dark adventure music & SFX).

static func generate_dark_adventure_music() -> AudioStreamWAV:
	# 16-second looping atmospheric dark medieval adventure soundtrack
	var sample_rate = 22050
	var duration = 16.0
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	# Frequencies: D minor / Dorian medieval modal chord progression
	var drone_freqs = [73.42, 58.27, 65.41, 55.0] # D2, Bb1, C2, A1
	var arpeggio_chords = [
		[146.83, 174.61, 220.0, 293.66, 349.23, 440.0],       # D minor
		[116.54, 146.83, 196.0, 233.08, 293.66, 392.0],       # Bb / Gm
		[130.81, 164.81, 196.0, 261.63, 329.63, 392.0],       # C major / Am
		[110.0,  138.59, 164.81, 220.0, 277.18, 293.66]        # A maj / Dm
	]
	
	# Melody notes across 16 beats (1 beat = 1 second)
	var melody_notes = [
		293.66, 0.0, 349.23, 440.0,   # D4, -, F4, A4
		392.0, 349.23, 329.63, 293.66, # G4, F4, E4, D4
		261.63, 329.63, 392.0, 440.0,  # C4, E4, G4, A4
		523.25, 440.0, 370.0, 293.66   # C5, A4, F#4, D4
	]

	var phase_drone: float = 0.0
	var phase_sub: float = 0.0
	var phase_arp: float = 0.0
	var phase_mel: float = 0.0
	var phase_bell: float = 0.0

	var current_arp_note: float = 293.66
	var last_arp_step = -1

	for i in range(total_samples):
		var time = float(i) / float(sample_rate)
		var bar_idx = int(time / 4.0) % 4
		var beat_idx = int(time) % 16
		
		# 1. Low dungeon drone
		var target_drone = drone_freqs[bar_idx]
		phase_drone += 2.0 * PI * target_drone / sample_rate
		phase_sub += 2.0 * PI * (target_drone * 0.5) / sample_rate
		if phase_drone > 2.0 * PI: phase_drone -= 2.0 * PI
		if phase_sub > 2.0 * PI: phase_sub -= 2.0 * PI
		var drone_val = (sin(phase_drone) * 0.6 + sin(phase_drone * 2.0) * 0.2 + sin(phase_sub) * 0.4) * 0.28

		# 2. Arpeggio harp notes
		var arp_step = int(time * 4.0)
		if arp_step != last_arp_step:
			last_arp_step = arp_step
			var chord = arpeggio_chords[bar_idx]
			var note_in_chord = (arp_step % 8)
			if note_in_chord < chord.size():
				current_arp_note = chord[note_in_chord]
			else:
				current_arp_note = chord[chord.size() - 1 - (note_in_chord - chord.size())]

		var arp_time_in_step = fmod(time, 0.25)
		var arp_env = maxf(0.0, 1.0 - arp_time_in_step * 3.8)
		phase_arp += 2.0 * PI * current_arp_note / sample_rate
		if phase_arp > 2.0 * PI: phase_arp -= 2.0 * PI
		var arp_val = (sin(phase_arp) + 0.3 * sin(phase_arp * 3.0)) * arp_env * 0.22

		# 3. Medieval melody flute/pipe
		var mel_freq = melody_notes[beat_idx]
		var mel_val = 0.0
		if mel_freq > 10.0:
			var beat_time = fmod(time, 1.0)
			var mel_env = sin(clampf(beat_time * PI, 0.0, PI))
			var vibrato = sin(time * 30.0) * 4.0
			phase_mel += 2.0 * PI * (mel_freq + vibrato) / sample_rate
			if phase_mel > 2.0 * PI: phase_mel -= 2.0 * PI
			mel_val = (sin(phase_mel) + 0.2 * sin(phase_mel * 2.0) + 0.1 * sin(phase_mel * 4.0)) * mel_env * 0.26

		# 4. Deep temple bell at start of each 4-second bar
		var bar_time = fmod(time, 4.0)
		var bell_env = exp(-bar_time * 1.8)
		var bell_freq = 220.0 if bar_idx % 2 == 0 else 196.0
		phase_bell += 2.0 * PI * bell_freq / sample_rate
		if phase_bell > 2.0 * PI: phase_bell -= 2.0 * PI
		var bell_val = (sin(phase_bell) + 0.5 * sin(phase_bell * 2.76) + 0.25 * sin(phase_bell * 5.4)) * bell_env * 0.18

		var noise = randf_range(-0.015, 0.015)
		var mixed = drone_val + arp_val + mel_val + bell_val + noise
		var s16 = int(clampf(mixed, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	return stream

static func generate_footstep() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.09
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(180.0, 60.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var tone = sin(phase)
		var noise = randf_range(-1.0, 1.0) * 0.6
		var env = pow(1.0 - t, 2.5)
		var val = (tone * 0.4 + noise * 0.6) * env * 0.5
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

static func generate_chest_open() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.75
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var phase_creak: float = 0.0
	var phase_chime: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var sample_val = 0.0

		if t < 0.35:
			var creak_t = t / 0.35
			var freq = lerpf(80.0, 240.0, creak_t) + sin(creak_t * 60.0) * 30.0
			phase_creak += 2.0 * PI * freq / sample_rate
			var wood_saw = fmod(phase_creak, 2.0 * PI) / PI - 1.0
			sample_val = wood_saw * sin(creak_t * PI) * 0.45
		else:
			var chime_t = (t - 0.35) / 0.65
			var chime_freq = 880.0 + sin(chime_t * 20.0) * 100.0
			phase_chime += 2.0 * PI * chime_freq / sample_rate
			var env = exp(-chime_t * 4.0)
			sample_val = (sin(phase_chime) + 0.4 * sin(phase_chime * 2.0)) * env * 0.6

		bytes.encode_s16(i * 2, int(clampf(sample_val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

static func generate_anvil_clink() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.45
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		p1 += 2.0 * PI * 1760.0 / sample_rate
		p2 += 2.0 * PI * 2640.0 / sample_rate
		var env = exp(-t * 9.0)
		var click = randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.4
		var sample_val = (sin(p1) * 0.6 + sin(p2) * 0.4 + click) * env * 0.6
		bytes.encode_s16(i * 2, int(clampf(sample_val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

static func generate_chapel_bell() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.6
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var p1: float = 0.0
	var p2: float = 0.0
	var p3: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		p1 += 2.0 * PI * 440.0 / sample_rate
		p2 += 2.0 * PI * 587.33 / sample_rate
		p3 += 2.0 * PI * 880.0 / sample_rate
		var env = exp(-t * 2.5)
		var sample_val = (sin(p1) * 0.5 + sin(p2) * 0.35 + sin(p3) * 0.15) * env * 0.6
		bytes.encode_s16(i * 2, int(clampf(sample_val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

static func generate_ui_click() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.06
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		phase += 2.0 * PI * lerpf(800.0, 400.0, t) / sample_rate
		var env = 1.0 - t
		var sample_val = sin(phase) * env * 0.4
		bytes.encode_s16(i * 2, int(clampf(sample_val, -1.0, 1.0) * 32767.0))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
