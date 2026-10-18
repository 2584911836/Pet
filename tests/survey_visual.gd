extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-v0.10.1.png")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_game()
	game.close_modal()
	game.set_tracking("survey")
	await capture("survey-explore")
	game.player = game.Surveys.POINTS[0].tile
	game.inspect_survey()
	await capture("survey-story")
	game.show_survey_journal()
	await capture("survey-journal")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
