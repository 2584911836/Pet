extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-v0.9.png")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	await capture("title")
	game.new_game()
	await capture("opening")
	game.close_modal()
	await capture("explore")
	game.show_quest_journal()
	await capture("journal")
	game.show_local_map()
	await capture("local-map")
	game.close_modal()
	game.visit_region(0,1)
	game.player = game.field_npc_position()+Vector2i.RIGHT
	game.interact_nearby()
	await capture("npc")
	game.close_modal()
	game.start_battle(13)
	await capture("battle")
	game.turn("flee")
	for size in [Vector2i(1024,768),Vector2i(1920,1080)]:
		root.size = size
		game.start_battle(13)
		await capture("battle-%dx%d" % [size.x,size.y])
		game.turn("flee")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
