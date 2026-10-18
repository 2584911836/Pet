extends SceneTree
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL REPORT: "+label)
func _initialize() -> void:
	call_deferred("run")
func reset_party() -> void:
	game.close_modal()
	game.new_game()
	game.close_modal()
	game.party = [game.creature(0,10),game.creature(1,10),game.creature(2,10)]
	game.active = 0
func win() -> void:
	while game.mode == "battle":
		game.enemy.hp = 1
		game.turn("attack")
	game.close_modal()
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	reset_party()
	game.start_battle(3)
	game.switch_to(1)
	check(game.battle_log.participants == [0,1] and game.battle_log.actions == 1,"valid switch records participation and one action")
	game.switch_to(1)
	check(game.battle_log.actions == 1,"selecting same active pet cannot add action or turn")
	win()
	check(game.party[0].xp == 1 and game.party[1].xp == 1 and game.party[2].xp == 0,"only real participants receive victory XP")
	check(game.last_battle_report.rows.size() == 2 and game.last_battle_report.points == 1,"report lists participants and actual points")
	check(game.last_battle_report.actions == 2,"switch plus winning attack counted")
	var xp_before: int = game.party[0].xp
	game.show_battle_report()
	game.show_battle_report()
	game.finish_battle("duplicate")
	check(game.party[0].xp == xp_before and game.wins == 1,"review and duplicate completion cannot reward twice")
	game.close_modal()
	game.fragments = 3
	game.start_battle(3)
	win()
	check(game.last_battle_report.points == 0,"capped qualification points shown accurately")
	reset_party()
	game.start_battle(3)
	game.focus = 0
	game.turn("skill")
	game.salves = 0
	game.turn("heal")
	check(game.battle_log.actions == 0,"invalid resource actions not counted")
	game.turn("flee")
	check(game.last_battle_report.outcome == "安全撤退" and game.last_battle_report.rows[0].earned == 0 and game.party[0].xp == 0,"flee gives no experience")
	reset_party()
	game.party = [game.creature(0,99)]
	game.start_battle(3)
	game.rng.seed = 17
	for retry in range(20):
		if game.mode != "battle": break
		game.enemy.hp = 1
		game.turn("capture")
	check(game.mode == "explore" and game.last_battle_report.captured == 3,"successful capture produces result")
	check(game.last_battle_report.rows.size() == 1 and game.party[1].xp == 0,"newly captured pet excluded from pre-capture participation")
	check(game.last_battle_report.capsules > 0 and game.last_battle_report.capsules == game.battle_log.capsules,"capsules counted across failed and successful attempts")
	reset_party()
	game.fragments = 3
	game.start_battle(2,true)
	win()
	check(game.last_battle_report.rows.size() == 3 and game.last_battle_report.rows[2].guidance and not game.last_battle_report.rows[2].participated,"mentor guidance distinguished from participation")
	check(game.party[2].level == 11 and game.party[2].xp == 0,"bench pet receives only first-clear mentor level")
	reset_party()
	game.completed = [true,true,true]
	game.zone = 2
	game.area = 2
	game.player = Vector2i(15,2)
	game.start_special_battle("rescue")
	game.enemy.hp = 1
	game.turn("attack")
	check(game.mode == "battle" and game.party[0].xp == 0 and game.last_battle_report.is_empty(),"multi-opponent battle does not settle early")
	win()
	check(game.last_battle_report.opponents.size() == 2 and game.party[0].xp == 1 and game.story_flags.get("parents_rescued",false),"full rescue roster settles exactly once")
	reset_party()
	game.party = [game.creature(0)]
	game.party[0].hp = 1
	game.start_battle(1)
	game.turn("guard")
	check(game.mode == "explore" and game.last_battle_report.outcome == "营地救援" and game.last_battle_report.rows[0].earned == 0,"defeat reports rescue without XP")
	reset_party()
	game.party[0] = game.creature(0)
	game.party[0].hp = 1
	game.start_battle(1)
	game.turn("guard")
	check(game.active == 1 and game.battle_log.participants == [0,1],"forced replacement joins participation")
	win()
	check(game.party[0].xp == 1 and game.party[1].xp == 1 and game.party[2].xp == 0,"knocked-out contributor still receives earned victory XP")
	reset_party()
	game.start_battle(3)
	game.turn("heal")
	check(game.battle_log.herbs == 1 and game.battle_log.actions == 1,"accepted healing records actual herb consumption")
	game.turn("flee")
	check(game.last_battle_report.herbs == 1 and game.last_battle_report.actions == 2,"withdrawal summary preserves resource use")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("Battle reports: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
