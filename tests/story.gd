extends SceneTree
var checks := 0
var failures := 0
var game

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL STORY: "+label)

func _initialize() -> void:
	call_deferred("run")

func win_current() -> void:
	while game.mode == "battle":
		game.enemy.hp = 1
		game.turn("attack")
	game.close_modal()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.close_modal()
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	check(game.modal_body.get_child(1).text.contains("父母") and not game.modal_body.get_child(1).text.contains("灯塔"),"new opening establishes missing parents without old setting")
	game.close_modal()
	check(game.Story.objective(game).goal == "grass","first objective is field training")
	check(game.quest_label.visible and game.guide_path.size() > 0,"persistent quest ribbon and route available")
	var first_button_id: int = game.buttons.get_child(0).get_instance_id()
	game.refresh()
	game.refresh()
	check(game.buttons.get_child(0).get_instance_id() == first_button_id,"walking/status refresh preserves unchanged action controls")
	for z in range(3):
		for a in range(3):
			check(game.encounter_pool(z,a).size() == 12,"all twelve local species available without phase gate")
	game.talk_keeper()
	game.show_keeper_topic("research")
	check(game.story_flags.get("topic_research",false),"branching research conversation records read state")
	game.close_modal()
	game.fragments = 3
	game.crystals[0] = 3
	game.refresh()
	check(game.Story.objective(game).goal == "arena","earned training points update main objective")
	check(game.guide_path.back() == Vector2i(15,2),"main route reaches the trainer arena")
	var previous: Vector2i = game.player
	for tile in game.guide_path:
		check(previous.distance_to(tile) == 1 and tile not in game.obstacle_tiles() and game.is_land(tile),"route uses legal adjacent tiles")
		previous = tile
	game.player = Vector2i(10,5)
	game.move_player(Vector2i.RIGHT)
	check(game.player == Vector2i(11,5),"center route never closes")
	game.show_local_map()
	check(game.modal != null and game.modal_body.get_child(0).text.contains("本区地图"),"local terrain map opens")
	game.close_modal()
	game.player = Vector2i(15,2)
	game.party = [game.creature(0),game.creature(1)]
	game.active = 0
	game.start_battle(2,true)
	win_current()
	check(game.completed[0] and game.party[1].level == 2,"first regional qualification trains the whole team once")
	game.visit_region(0,1)
	check(game.Story.objective(game).area == 0,"regional challenge points back to town rather than a duplicate field arena")
	game.player = game.field_npc_position()+Vector2i.RIGHT
	game.known = []
	for id in range(108):
		if int(game.SPECIES[id].island) == 0 and int(game.SPECIES[id].area) == 1 and game.known.size() < 4: game.known.append(id)
	game.interact_nearby()
	check(game.modal_body.get_child(0).text.contains("茵禾"),"R interaction targets nearby field researcher")
	var before: int = game.seals
	game.claim_field_reward()
	check(game.seals == before+3,"research quest grants one reward")
	game.claim_field_reward()
	check(game.seals == before+3,"research reward cannot be farmed")
	game.close_modal()
	game.visit_region(0,2)
	game.player = game.field_npc_position()+Vector2i.RIGHT
	game.interact_nearby()
	check(game.modal_body.get_child(0).text.contains("乔渡"),"patrol NPC has independent conversation")
	game.show_patrol_question()
	before = game.seals
	game.patrol_wrong_answer()
	check(game.seals == before and not game.story_flags.get("field_reward_0_2",false),"wrong patrol answer gives no reward or penalty")
	game.show_patrol_question()
	game.claim_field_reward()
	check(game.story_flags.get("field_reward_0_2",false) and game.seals == before+3,"correct patrol answer completes persistent side quest")
	game.close_modal()
	game.player = Vector2i(2,6)
	game.set_tracking("field")
	check(game.tracked_goal == "field" and not game.guide_path.is_empty(),"NPC route tracking works")
	game.save_game(false)
	game.story_flags.clear()
	game.load_game()
	check(game.story_flags.get("field_reward_0_2",false) and game.tracked_goal == "field","dialogue and side quest progress persist")
	game.completed = [true,true,false]
	game.zone = 2
	game.area = 2
	game.player = Vector2i(15,2)
	game.start_special_battle("rescue")
	check(game.mode == "explore","rescue locked before third qualification")
	game.completed = [true,true,true]
	game.guardian_defeated = true
	check(not game.story_flags.get("parents_rescued",false) and game.Story.objective(game).zone == 2 and game.Story.objective(game).area == 2,"three badges unlock rescue rather than ending story")
	game.party = [game.creature(0,99)]
	game.active = 0
	game.start_special_battle("championship")
	check(game.mode == "explore","championship locked before parents rescued")
	game.start_special_battle("rescue")
	check(game.mode == "battle" and game.special_battle_kind == "rescue" and game.guardian_battle,"rescue is a distinct trainer battle")
	await process_frame
	await process_frame
	check(game.buttons is GridContainer and game.buttons.columns == 2,"battle actions use two columns")
	for button in game.buttons.get_children():
		if button.text.contains("不可捕捉"): check(button.disabled,"trainer capture button disabled")
	game.enemy.hp = 1
	game.turn("attack")
	check(game.mode == "battle" and game.opponent_slot == 1 and not game.story_flags.get("parents_rescued",false),"rescue requires defeating full opposing roster")
	win_current()
	check(game.story_flags.get("parents_rescued",false) and not game.story_flags.get("champion",false),"rescue victory saves parents without awarding championship")
	check(game.Story.objective(game).area == 0,"rescued parents unlock return to league center")
	game.area = 0
	game.player = Vector2i(15,2)
	game.start_special_battle("championship")
	check(game.special_battle_kind == "championship" and game.enemy.species == 68,"championship has separate opponent and state")
	win_current()
	check(game.story_flags.get("champion",false) and game.Story.objective(game).goal == "camp","fifth story challenge reaches postgame")
	game.save_game(false)
	game.story_flags.clear()
	game.load_game()
	check(game.story_flags.get("parents_rescued",false) and game.story_flags.get("champion",false),"both finale outcomes survive reload")
	game.start_special_battle("championship")
	check(game.mode == "explore","completed final cannot be replayed for infinite rewards")
	game.start_battle(1)
	game.party = [game.creature(2,10),game.creature(0,10)]
	game.active = 0
	game.focus = 2
	game.salves = 1
	game.refresh()
	await process_frame
	await process_frame
	for button in game.buttons.get_children():
		check(game.action_scroll.get_global_rect().encloses(button.get_global_rect()),"all battle actions fit without scrolling")
	game.show_battle_party()
	var round_before: int = game.enemy_round
	game.close_modal()
	check(game.enemy_round == round_before,"cancel party choice spends no turn")
	game.show_battle_party()
	game.select_battle_party(1)
	check(game.active == 1 and game.enemy_round == round_before+1 and game.focus == 2 and game.salves == 1,"party selection spends one turn and preserves resources")
	game.turn("flee")
	game.save_game(false)
	var path: String = game.SAVE_PATH
	var legacy = JSON.parse_string(FileAccess.get_file_as_string(path))
	legacy.erase("story_flags")
	legacy.erase("tracked_goal")
	legacy["tide"] = 1 # Old field is ignored, never used to gate routes or spawns.
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	game.load_game()
	check(game.completed.count(true) == 3 and not game.story_flags.get("parents_rescued",false),"old three-beacon save maps to three licenses and new rescue remains playable")
	check(game.Story.objective(game).area == 2,"legacy save receives valid next objective")
	var s: Dictionary = game.SPECIES[8]
	var status: Dictionary = game.Signature.state()
	var target: Dictionary = game.Signature.state()
	var pet := {"hp":100,"max_hp":100}
	game.Signature.apply(s,pet,status,target,false)
	check(status.shield > 0,"reworked burst skill grants shield at healthy life")
	check(game.Signature.bonus(s,{"hp":50,"max_hp":100},true) == int(s.skill_value)*2,"reworked burst grants extra damage when caster low")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("STORY RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
