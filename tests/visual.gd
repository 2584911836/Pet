extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://build/"+name+".png")
	if result != OK: quit(1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	root.size = Vector2i(1152,720)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await capture("title-v0.5")
	game.close_modal()
	game.refresh()
	await capture("explore-v0.5")
	game.tide = 1
	game.start_battle(2)
	await capture("battle-v0.5")
	game.show_settings()
	await capture("settings-v0.5")
	game.close_modal()
	game.turn("flee")
	game.open_dex()
	await capture("dex-v0.5")
	game.show_pet_detail(107)
	await capture("pet-detail-v0.5")
	game.close_modal()
	game.show_world_map()
	await capture("map-v0.5")
	game.show_character()
	await capture("character-v0.5")
	game.close_modal()
	game.player = Vector2i(2,5)
	game.talk_keeper()
	await capture("keeper-v0.5")
	game.show_title()
	for view in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(1920,1080)]:
		root.size = view
		await capture("title-v0.5-%dx%d" % [view.x,view.y])
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
