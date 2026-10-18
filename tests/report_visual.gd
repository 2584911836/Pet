extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-v0.11.png")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	game.party = [game.creature(0,5),game.creature(1,5),game.creature(2,5)]
	game.party[0].xp = 2
	game.start_battle(3)
	game.switch_to(1)
	game.enemy.hp = 1
	game.turn("attack")
	await capture("battle-report")
	game.close_modal()
	game.fragments = 3
	game.start_battle(2,true)
	game.enemy.hp = 1
	game.turn("attack")
	game.show_battle_report()
	await capture("mentor-report")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
