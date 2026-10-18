extends SceneTree
# Simulates combat and chapter objectives through normal actions, skipping walking time.
# It does not set health, levels, enemy health, crystals, or victory flags.
var game
var total_battles := 0
var failed_seeds: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	for seed_value in range(20):
		game.new_game()
		game.close_modal()
		game.rng.seed = seed_value+400
		var battles := 0
		while game.completed.count(true) < 3 and battles < 90:
			game.player = Vector2i(2,5)
			game.rest()
			if game.completed[game.zone]:
				game.navigate_region(game.zone,2)
				game.travel(game.zone+1)
				game.close_modal()
			# Choose the most effective healthy companion at camp.
			game.area = battles%3
			var target: int = game.ISLANDS[game.zone].boss if game.fragments >= 3 else game.pick_encounter()
			var best := -1.0
			for i in range(game.party.size()):
				var p: Dictionary = game.party[i]
				var s: Dictionary = game.SPECIES[int(p.species)]
				var score: float = game.Elements.multiplier(int(game.Moves.list(s)[2].element),game.SPECIES[target].elements)*(int(s.power)+int(p.level)*2)*int(p.max_hp)
				if score > best:
					best = score
					game.active = i
			game.start_battle(target,game.fragments >= 3)
			resolve_battle(target)
			battles += 1
			await process_frame
		for kind in ["rescue","championship"]:
			var flag: String = "parents_rescued" if kind == "rescue" else "champion"
			for attempt in range(6):
				game.visit_region(2,2 if kind == "rescue" else 0)
				game.close_modal()
				game.player = Vector2i(2,6)
				game.rest()
				game.player = Vector2i(15,2)
				game.start_special_battle(kind)
				resolve_battle(13 if kind == "rescue" else 68)
				battles += 1
				await process_frame
				if game.story_flags.get(flag,false): break
				# If under-levelled, play three normal practice encounters; no stat mutation.
				game.visit_region(0,0)
				for practice in range(3):
					game.player = Vector2i(2,6)
					game.rest()
					game.start_battle(2)
					resolve_battle(2)
					battles += 1
					await process_frame
			if not game.story_flags.get(flag,false): break
		total_battles += battles
		if game.completed.count(true) < 3 or not game.story_flags.get("champion",false): failed_seeds.append(seed_value)
		print("CAMPAIGN seed=%d licenses=%d battles=%d dex=%d rescued=%s champion=%s" % [seed_value,game.completed.count(true),battles,game.discovered(),str(game.story_flags.get("parents_rescued",false)),str(game.story_flags.get("champion",false))])
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("CAMPAIGN RESULT: 20 seeds, %d failures, %d battles" % [failed_seeds.size(),total_battles])
	quit(1 if not failed_seeds.is_empty() else 0)

func resolve_battle(target: int) -> void:
	var turns := 0
	var throws := 0
	while game.mode == "battle" and turns < 40:
		var p: Dictionary = game.party[game.active]
		var action := "attack"
		if int(p.hp) < int(p.max_hp)*0.5 and game.salves > 0: action = "heal"
		elif not game.guardian_battle and not game.known.has(target) and float(game.enemy.hp) < float(game.enemy.max_hp)*0.65 and throws < 3:
			action = "capture"
			throws += 1
		elif game.focus >= 2: action = "skill"
		game.turn(action)
		turns += 1
	if game.mode == "battle": game.turn("flee")
	game.close_modal()
