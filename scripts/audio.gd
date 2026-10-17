extends Node
# Original synthesized score and effects. No external audio recordings.
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var enabled := true
var use_baked := true
var current_track := ""
var cache: Dictionary = {}

func _ready() -> void:
	music = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	add_child(music)
	add_child(effects)
	music.volume_db = -18
	effects.volume_db = -12

func synth(notes: Array, beat: float, looped: bool = false) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(notes.size()*beat*rate)
	var data := PackedByteArray()
	data.resize(frames*2)
	for i in range(frames):
		var step := mini(notes.size()-1,int(float(i)/rate/beat))
		var local: float = fmod(float(i)/rate,beat)
		var freq := 440.0*pow(2.0,(float(notes[step])-69.0)/12.0)
		var envelope := minf(1.0,local/0.015)*pow(maxf(0.0,1.0-local/beat),1.7)
		var wave := sin(TAU*freq*local)*0.6 + sin(TAU*freq*2*local)*0.15
		var bass := sin(TAU*freq*0.5*local)*0.2
		var value := int(clampf((wave+bass)*envelope*0.4,-1,1)*32767)
		data.encode_s16(i*2,value if int(notes[step]) > 0 else 0)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = frames
	return stream

func play_track(track: String) -> void:
	if current_track == track: return
	current_track = track
	var asset_path := "res://assets/audio/"+track+".wav"
	if use_baked and not cache.has(track) and ResourceLoader.exists(asset_path):
		var stored := load(asset_path) as AudioStreamWAV
		stored.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stored.loop_end = int(stored.data.size()/2)
		cache[track] = stored
	if not cache.has(track):
		var melodies := {
			"title":[60,64,67,72,71,67,64,62,60,64,69,72,71,69,67,0,57,60,64,67,65,64,62,60,59,62,65,69,67,65,62,0],
			"island_0":[60,64,67,71,69,67,64,62,60,64,67,72,71,67,64,0,57,60,64,67,65,64,62,60,59,62,65,69,67,65,62,0],
			"island_1":[57,60,64,67,64,60,59,0,57,59,60,64,62,60,59,0,53,57,60,65,64,60,57,0,55,59,62,67,64,62,59,0],
			"island_2":[62,65,69,74,72,69,65,0,62,67,69,76,74,69,67,0,60,64,67,72,71,67,64,0,57,62,65,69,67,65,62,0],
			"battle":[57,64,60,64,59,65,62,65,57,64,67,64,62,60,59,55,57,60,64,69,67,64,60,64,59,62,65,69,67,65,62,59],
			"guardian":[50,57,62,65,62,57,53,57,50,57,60,65,64,60,57,53,48,55,60,64,67,64,60,55,45,52,57,60,64,60,57,52]
		}
		var notes: Array = melodies.get(track,melodies.island_0)
		var beat := 0.20 if track == "battle" else 0.23 if track == "guardian" else 0.46 if track == "island_1" else 0.38
		cache[track] = synth_score(notes,beat,track in ["battle","guardian"])
	music.stream = cache[track]
	if enabled: music.play()

func synth_score(notes: Array, beat: float, percussion: bool) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(notes.size()*beat*rate)
	var data := PackedByteArray()
	data.resize(frames*2)
	var chords := [[48,52,55],[45,48,52],[41,45,48],[43,47,50]]
	for i in range(frames):
		var time := float(i)/rate
		var step := mini(notes.size()-1,int(time/beat))
		var local := fmod(time,beat)
		var frequency := 440.0*pow(2.0,(float(notes[step])-69)/12)
		var env := minf(1,local/0.012)*pow(maxf(0,1-local/beat),1.7)
		var melody := (sin(TAU*frequency*local)*0.23+sin(TAU*frequency*2*local)*0.045)*env if int(notes[step]) > 0 else 0.0
		var chord: Array = chords[int(step/8)%4]
		var pad := 0.0
		for note in chord: pad += sin(TAU*440*pow(2.0,(float(note)-69)/12)*time)*0.025
		var bass_frequency := 440.0*pow(2.0,(float(chord[0])-81)/12)
		var bass := sin(TAU*bass_frequency*local)*pow(maxf(0,1-local/beat),2)*0.11
		var rhythm := 0.0
		if percussion:
			var drum_t := fmod(time,beat*2)
			rhythm = sin(TAU*(65*drum_t-20*drum_t*drum_t))*exp(-drum_t*25)*0.14
			rhythm += sin(float(i)*1.734)*exp(-local*70)*0.035
		var fade := minf(1,minf(time,(float(frames)/rate)-time)/0.02)
		data.encode_s16(i*2,int(clampf((melody+pad+bass+rhythm)*fade,-0.9,0.9)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	return stream

func sfx(kind: String) -> void:
	if not enabled: return
	if not cache.has(kind):
		var notes := [72,79] if kind == "step" else [60,67,72,79] if kind == "win" else [76,64,52] if kind == "hit" else [67,72,79]
		cache[kind] = synth(notes,0.065)
	effects.stream = cache[kind]
	effects.play()

func set_volume(value: float) -> void:
	enabled = value > 0
	music.volume_db = linear_to_db(value*0.22) if enabled else -80
	effects.volume_db = linear_to_db(value*0.45) if enabled else -80
	if enabled and music.stream != null and not music.playing: music.play()
	if not enabled: music.stop()

func shutdown() -> void:
	enabled = false
	music.stop()
	effects.stop()
	music.stream = null
	effects.stream = null
	cache.clear()

func _exit_tree() -> void:
	shutdown()
