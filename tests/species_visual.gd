extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.dex_page = 1
	game.known = range(108)
	game.show_dex()
	await capture("dex-v0.7")
	game.show_pet_detail(13)
	await capture("detail-v0.7")
	game.close_modal()
	game.party = [game.creature(13,5),game.creature(14,5)]
	game.active = 0
	game.start_battle(91)
	game.turn("skill")
	await capture("battle-v0.7")
	game.turn("flee")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
