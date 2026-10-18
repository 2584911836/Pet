extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-v0.10.png")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	game.completed = [true,true,true]
	for node in range(9):
		game.visit_region(int(node/3),node%3)
		await capture("world-%d" % node)
	game.show_backpack_pet(false,0)
	await capture("growth")
	game.close_modal()
	game.show_local_map()
	await capture("local-map")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
