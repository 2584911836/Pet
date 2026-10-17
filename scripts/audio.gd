extends Node
# Original synthesized score and effects. No external audio recordings.
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var enabled := true
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
	if not cache.has(track):
		var notes: Array
		var beat: float
		if track == "battle":
			notes = [57,64,60,64,59,65,62,65,57,64,67,64,62,60,59,55]
			beat = 0.22
		else:
			notes = [60,64,67,71,69,67,64,62,60,64,67,72,71,67,64,0,57,60,64,67,65,64,62,60,59,62,65,69,67,65,62,0]
			beat = 0.42
		cache[track] = synth(notes,beat,true)
	music.stream = cache[track]
	if enabled: music.play()

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

func _exit_tree() -> void:
	music.stop()
	effects.stop()
	music.stream = null
	effects.stream = null
	cache.clear()
