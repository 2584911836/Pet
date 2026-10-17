extends SceneTree
# Development-only tool: score source is in audio.gd. Game ships the resulting WAVs.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	var audio := preload("res://scripts/audio.gd").new()
	root.add_child(audio)
	audio.use_baked = false
	for track in ["title","island_0","island_1","island_2","battle","guardian"]:
		audio.play_track(track)
		var stream: AudioStreamWAV = audio.cache[track]
		if stream.save_to_wav("res://assets/audio/"+track+".wav") != OK:
			quit(1)
			return
		print("BAKED ",track," ",stream.data.size()," bytes")
		audio.music.stop()
		await process_frame
	audio.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
