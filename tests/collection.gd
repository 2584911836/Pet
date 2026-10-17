extends SceneTree
# Verify collection mechanics at the supported late-game level, not first-run balancing.
# Every recruit is acquired by the actual soothe/capture actions in a valid encounter pool.
var game
var failures := 0
var captured := 0
var attempts := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.close_modal()
	game.party = [game.creature(0,99)]
	game.reserve = []
	game.known = [0]
	game.active = 0
	game.collection_rewarded = false
	game.completed = [true,true,true]
	game.rng.seed = 73291
	for id in range(1,108):
		var species: Dictionary = game.SPECIES[id]
		game.visit_region(int(species.island),int(species.area))
		game.tide = maxi(0,int(species.tide))
		if not game.encounter_pool().has(id):
			printerr("Unreachable species ",id)
			failures += 1
			continue
		for retry in range(4):
			game.player = Vector2i(2,5)
			game.rest()
			game.start_battle(id)
			for turn in range(15):
				if game.mode != "battle" or game.seals <= 0: break
				if game.focus > 0 and game.enemy.hp > game.enemy.max_hp/3:
					game.turn("soothe")
				else:
					game.turn("capture")
					attempts += 1
			if game.mode == "battle": game.turn("flee")
			game.close_modal()
			if game.known.has(id): break
		if game.known.has(id): captured += 1
		else:
			printerr("Capture failed for species ",id)
			failures += 1
		await process_frame
	game.save_game(false)
	game.load_game()
	if game.discovered() != 108 or game.party.size()+game.reserve.size() != 108 or not game.collection_rewarded:
		failures += 1
		printerr("Collection/save/completion badge mismatch")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("COLLECTION RESULT: %d/107 wild recruits, %d seal attempts, %d failures" % [captured,attempts,failures])
	quit(1 if failures else 0)
