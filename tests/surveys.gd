extends SceneTree
var game
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL SURVEY: "+label)
func _initialize() -> void:
	call_deferred("run")
func path_to(target: Vector2i) -> bool:
	var queue := [game.player]
	var seen := {game.player:true}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == target: return true
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var n: Vector2i = p+d
			if seen.has(n) or not game.is_land(n) or n in game.obstacle_tiles() or n in [Vector2i(2,5),Vector2i(3,4)] or game.exit_destination(n) >= 0: continue
			seen[n] = true
			queue.append(n)
	return false
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	check(game.Surveys.count(game.story_flags) == 0,"new game has no invented observations")
	game.inspect_survey()
	check(game.Surveys.count(game.story_flags) == 0,"remote observation rejected")
	game.claim_survey_report()
	check(not game.story_flags.get("survey_report_0",false),"incomplete report rejected")
	game.completed = [true,true,true]
	for i in range(9):
		game.visit_region(int(i/3),i%3)
		var point: Vector2i = game.Surveys.POINTS[i].tile
		check(game.is_land(point) and point not in game.obstacle_tiles() and path_to(point),"every clue reachable under real terrain")
		check(not game.is_grass(point),"observation stand has no random encounter")
		game.player = point
		var capsules: int = game.seals
		game.interact_nearby()
		check(game.story_flags.get(game.Surveys.key(i),false) and game.seals == capsules+2,"R records local clue and grants one reward")
		check(game.modal_body.get_child(0).text == game.Surveys.POINTS[i].title,"local story page opens")
		game.close_modal()
		game.inspect_survey()
		check(game.seals == capsules+2,"re-reading cannot duplicate reward")
		game.close_modal()
		if i%3 == 2:
			game.claim_survey_report()
			check(not game.story_flags.get("survey_report_%d" % game.zone,false),"report requires nearby researcher")
			game.player = Vector2i(2,6)
			capsules = game.seals
			game.claim_survey_report()
			check(game.story_flags.get("survey_report_%d" % game.zone,false) and game.seals == capsules+3,"complete regional report rewards once at camp")
			game.claim_survey_report()
			check(game.seals == capsules+3,"report cannot be farmed")
			game.close_modal()
	check(game.Surveys.count(game.story_flags) == 9,"all nine independent records collected")
	game.set_tracking("survey")
	game.save_game(false)
	game.story_flags.clear()
	game.load_game()
	check(game.Surveys.count(game.story_flags) == 9 and game.tracked_goal == "survey","new flags and tracker survive save")
	game.new_game()
	game.close_modal()
	game.set_tracking("survey")
	check(game.guide_path.back() == game.Surveys.POINTS[0].tile and game.quest_label.text.contains("调查"),"survey tracker leads to clue and labels HUD")
	game.player = game.Surveys.POINTS[0].tile
	game.inspect_survey()
	game.close_modal()
	check(game.guide_path.back() == game.region_exit_tile(1),"tracker switches to next area road")
	game.mode = "battle"
	var before: int = game.Surveys.count(game.story_flags)
	game.inspect_survey()
	game.claim_survey_report()
	check(game.Surveys.count(game.story_flags) == before,"combat cannot claim exploration rewards")
	game.mode = "explore"
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("Surveys: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
