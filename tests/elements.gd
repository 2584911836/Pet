extends SceneTree
const E = preload("res://scripts/elements.gd")
const M = preload("res://scripts/battle_moves.gd")
var checks := 0
var failures := 0
var game

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ELEMENTS: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Independent named specification, matching the approved table.
	var approved := {"金":["木","冰","土","龙"],"木":["水","土"],"水":["火","虫"],"火":["金","木","冰","虫"],"土":["水","火","雷"],"风":["土","虫"],"雷":["水","金","风"],"光":["暗"],"暗":["光"],"冰":["木","水","风"],"龙":["龙"],"虫":["木"]}
	for a in range(12):
		for d in range(12):
			var expected := 1.5 if approved[E.NAMES[a]].has(E.NAMES[d]) else 1.0
			check(is_equal_approx(E.single(a,d),expected),"matrix "+E.NAMES[a]+" -> "+E.NAMES[d])
	check(E.multiplier(3,[0,4]) == 2.0,"dual weakness capped at two")
	check(E.multiplier(3,[0,0]) == 1.5,"duplicate element never stacks")
	check(E.single(10,10) == 1.5 and E.single(7,8) == 1.5 and E.single(8,7) == 1.5,"dragon self and light dark exceptions")
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.close_modal()
	game.set_process(false)
	game.animations_enabled = false
	var present: Dictionary = {}
	for s in game.SPECIES:
		check(s.elements.size() >= 1 and s.elements.size() <= 2,"one or two species elements")
		check(s.elements.size() == 1 or s.elements[0] != s.elements[1],"no duplicate species element")
		for element in s.elements: present[element] = true
		var moves: Array = M.list(s)
		check(moves.size() == 3,"three equipped moves")
		for move in moves:
			check(int(move.element) >= 0 and int(move.element) < 12 and int(move.cost) >= 0 and int(move.cost) <= 2,"valid typed move and cost")
	check(present.size() == 12,"all twelve elements represented")
	game.party = [game.creature(2,4)] # water basic, ice coverage
	game.active = 0
	game.start_battle(1) # fire
	game.enemy.hp = 1000
	game.enemy.max_hp = 1000
	game.focus = 0
	var hp: int = game.enemy.hp
	var rounds: int = game.enemy_round
	game.turn("move:1")
	check(game.enemy.hp == hp and game.enemy_round == rounds and game.focus == 0,"unaffordable move never spends turn")
	game.turn("attack")
	check(game.focus == 1 and game.enemy.hp < hp and game.message.contains("克制 ×1.50"),"zero cost typed basic restores focus and applies weakness")
	game.turn("move:1")
	check(game.focus == 0 and game.message.contains("冰"),"coverage move uses its own element and cost")
	game.turn("move:99")
	check(game.focus == 0 and game.enemy_round == rounds+2,"invalid move cannot bypass validation")
	game.turn("flee")
	game.start_battle(1)
	check(game.enemy_focus == 3,"enemy resource reset")
	game.party[0].max_hp = 1000
	game.party[0].hp = 1000
	for i in range(3): game.turn("guard")
	check(game.enemy_focus >= 0 and game.enemy_focus <= 3 and game.message.contains(game.SPECIES[1].skill),"enemy uses its signature within resource budget")
	game.turn("flee")
	game.show_elements()
	check(game.modal_body.get_child_count() >= 15,"all twelve relationship rows available in manual")
	game.party = [game.creature(0),game.creature(102)]
	game.active = 1
	game.save_game(false)
	game.party = [game.creature(1)]
	game.active = 0
	game.load_game()
	check(game.party[1].species == 102 and game.SPECIES[102].elements.size() == 2,"legacy creature records resolve dual elements without save migration")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("ELEMENT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
