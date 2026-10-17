extends SceneTree

var checks := 0
var failures := 0
var game

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + description)
	else: print("PASS: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.party = [game.creature(0)]
	game.active = 0
	game.seals = 8
	game.fragments = 0
	game.wins = 0
	game.guardian_defeated = false
	game.player = Vector2i(2,5)
	check(game.effectiveness(0,2) == 1.5, "forest beats tide")
	check(game.effectiveness(1,0) == 1.5, "ember beats forest")
	check(game.effectiveness(2,1) == 1.5, "tide beats ember")
	check(game.effectiveness(0,1) == 0.7, "resistance works")
	game.move_player(Vector2i(-1,0))
	game.move_player(Vector2i(-1,0))
	check(game.player.x == 1, "water boundary blocks movement")
	game.start_battle(2)
	var before: int = game.enemy.hp
	game.turn("skill")
	check(game.enemy.hp < before and game.party[0].hp < game.party[0].max_hp, "skill and enemy retaliation execute")
	game.enemy.hp = 1
	game.turn("attack")
	check(game.mode == "explore" and game.fragments == 1, "victory grants crystal and exits battle")
	for i in range(2):
		game.start_battle(1)
		game.enemy.hp = 1
		game.turn("attack")
	check(game.party[0].level == 2 and game.party[0].hp == game.party[0].max_hp, "three victories level up and heal")
	game.player = Vector2i(14,2)
	game.move_player(Vector2i(1,0))
	check(game.mode == "battle" and game.guardian_battle, "three crystals unlock guardian")
	var seals_before: int = game.seals
	game.turn("capture")
	check(game.seals == seals_before and game.mode == "battle", "guardian capture rejected without consuming seal")
	game.enemy.hp = 1
	game.turn("attack")
	check(game.guardian_defeated, "guardian victory completes demo")
	game.start_battle(1)
	game.enemy.hp = 1
	game.seals = 100
	# Fix the seed, then allow repeated attempts to exercise the real capture path.
	game.rng.seed = 2026
	for i in range(20):
		if game.mode != "battle": break
		game.party[0].hp = game.party[0].max_hp
		game.turn("capture")
	check(game.party.size() == 2 and game.seals < 100, "capture consumes seal and recruits creature")
	game.heal_party()
	game.start_battle(0)
	game.switch_to(1)
	check(game.active == 1 and game.party[1].hp < game.party[1].max_hp, "switching grants enemy a turn")
	for p in game.party: p.hp = 1
	game.enemy.hp = game.enemy.max_hp
	game.turn("guard")
	# Force a complete defeat with the enemy's actual damage path.
	for p in game.party: p.hp = 0
	game.enemy_turn()
	check(game.mode == "explore" and game.player == Vector2i(2,5), "defeat returns to camp")
	check(game.party[0].hp == game.party[0].max_hp and game.party[1].hp == game.party[1].max_hp, "defeat recovers whole party")
	game.seals = 0
	game.rest()
	check(game.seals == 8, "camp replenishes seals")
	game.save_game(false)
	game.party = [game.creature(2)]
	game.guardian_defeated = false
	game.load_game()
	check(game.party.size() == 2 and game.guardian_defeated and game.seals == 8, "save/load preserves roster, progress, supplies")
	game.close_modal()
	game.mode = "explore"
	game.tide = 0
	game.change_tide()
	check(game.tide == 1, "bell changes tide")
	game.player = Vector2i(10,5)
	game.move_player(Vector2i(1,0))
	check(game.player.x == 10, "high tide blocks shallow crossing")
	game.change_tide()
	game.move_player(Vector2i(1,0))
	check(game.player.x == 11, "low tide opens crossing")
	game.change_tide()
	check(game.player.x == 10, "rising tide rescues player from flooded tile")
	game.start_battle(1)
	game.focus = 0
	var hp_before: int = game.enemy.hp
	game.turn("skill")
	check(game.enemy.hp == hp_before, "skill unavailable without focus")
	game.turn("attack")
	check(game.focus == 1, "normal attack restores focus")
	game.salves = 0
	var hero_hp: int = game.party[game.active].hp
	game.turn("heal")
	check(game.party[game.active].hp == hero_hp, "exhausted herbs cannot heal")
	game.turn("flee")
	game.player = Vector2i(2,5)
	game.heal_party()
	game.party = [game.creature(0),game.creature(1),game.creature(2),game.creature(3),game.creature(4),game.creature(5)]
	game.reserve = [game.creature(6)]
	game.active = 0
	game.withdraw(0)
	check(game.party.size() == 6 and game.party[0].species == 6 and game.reserve[0].species == 0, "camp swaps full party with reserve")
	game.close_modal()
	game.completed = [true,false,false]
	game.travel(2)
	check(game.zone == 0, "island progression gate blocks skipping chapters")
	game.travel(1)
	check(game.zone == 1 and game.fragments == 0, "travel starts fresh island crystal objective")
	game.close_modal()
	game.fragments = 3
	game.crystals[1] = 3
	game.start_battle(4,true)
	game.enemy.hp = 1
	game.turn("attack")
	check(game.completed[1], "second beacon completes chapter")
	game.close_modal()
	game.travel(2)
	game.close_modal()
	game.start_battle(8,true)
	game.enemy.hp = 1
	game.turn("attack")
	check(game.completed.count(true) == 3, "third beacon reaches ending")
	game.close_modal()
	game.known = [0,1,2,3,4,5,6,7,8]
	game.save_game(false)
	game.zone = 0
	game.reserve = []
	game.known = [0]
	game.load_game()
	check(game.zone == 2 and game.reserve.size() == 1 and game.discovered() == 9, "save restores chapters, reserve and persistent dex")
	check(not game.valid_creature({"species":99}), "malformed creatures rejected")
	var bad: Dictionary = game.creature(0)
	bad.hp = -1
	check(not game.valid_creature(bad), "negative save health rejected")
	var file := FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	game.load_game()
	check(game.zone == 2, "broken save does not overwrite live state")
	game.save_game(false)
	await process_frame
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
