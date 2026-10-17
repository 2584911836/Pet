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
	root.size = Vector2i(1152,720)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await capture("title-v0.3")
	game.close_modal()
	game.refresh()
	await capture("explore-v0.3")
	game.start_battle(2)
	await capture("battle-v0.3")
	game.show_settings()
	await capture("settings-v0.3")
	game.queue_free()
	await process_frame
	quit()
