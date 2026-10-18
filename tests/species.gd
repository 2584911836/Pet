extends SceneTree

const Signature = preload("res://scripts/signature_skills.gd")
var checks := 0
var failures := 0
var game

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL SPECIES: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.close_modal()
	game.set_process(false)
	game.animations_enabled = false
	var skills: Dictionary = {}
	var lore: Dictionary = {}
	var profiles: Dictionary = {}
	var kinds: Dictionary = {}
	for id in range(108):
		var s: Dictionary = game.SPECIES[id]
		check(not skills.has(s.skill),"unique skill name %d" % id)
		check(not lore.has(s.lore),"independent ecology %d" % id)
		skills[s.skill] = true
		lore[s.lore] = true
		var profile := "%s/%d/%.2f/%d" % [s.skill_kind,s.skill_value,s.skill_scale,s.trait]
		check(not profiles.has(profile),"distinct mechanical profile %d" % id)
		profiles[profile] = true
		kinds[s.skill_kind] = true
		check(Signature.KINDS.has(s.skill_kind) and int(s.skill_value) >= 3 and int(s.skill_value) <= 10,"valid effect tuning %d" % id)
		check(Signature.description(s).length() > 20,"inspectable skill rules %d" % id)
		game.party = [game.creature(id)]
		game.party[0].max_hp = 1000
		game.party[0].hp = 500
		game.active = 0
		game.start_battle(0)
		game.enemy.max_hp = 1000
		game.enemy.hp = 1000
		game.rng.seed = 100+id
		game.turn("skill")
		check(game.enemy.hp < 1000 and game.mode == "battle","skill executes in actual combat %d" % id)
		var own: Dictionary = game.current_status()
		var target: Dictionary = game.enemy_status
		match str(s.skill_kind):
			"burn": check(int(target.dot_turns) == 1 and int(target.dot) == int(s.skill_value),"burn ticks and duration")
			"poison": check(int(target.dot_turns) == 2 and int(target.dot) == maxi(1,int(s.skill_value)-2),"poison ticks and duration")
			"shield": check(int(own.shield) >= 0 and int(game.party[0].hp) >= 500-maxi(0,(int(game.SPECIES[0].power)+int(game.enemy.level))*2-int(s.skill_value)*2),"shield absorbs retaliation")
			"regen": check(int(own.regen_turns) == 1,"regen advances once per action")
			"break": check(int(target.broken) == 2,"break retained for followup attacks")
			"echo": check(int(own.echo) == int(s.skill_value)*2,"echo retained for followup attack")
			"mark": check(int(target.mark) == int(s.skill_value)*2,"mark retained for followup attack")
			"focus": check(game.focus == 2,"focus skill refunds one tide point")
		game.turn("flee")
		game.start_battle(0)
		check(Signature.status_text(game.current_status()).is_empty() and Signature.status_text(game.enemy_status).is_empty(),"battle statuses reset %d" % id)
	check(kinds.size() == 11,"eleven functioning signature effect families")
	var own := Signature.state()
	var target := Signature.state()
	own.echo = 8
	target.mark = 6
	target.broken = 2
	target.break_value = 4
	target.shield = 10
	check(Signature.direct_damage(20,own,target) == 28,"followup effects combine before shield absorption")
	check(own.echo == 0 and target.mark == 0 and target.broken == 1 and target.shield == 0,"consumable status effects expire correctly")
	var pet := {"hp":50,"max_hp":100}
	target = Signature.state()
	target.regen = 5
	target.regen_turns = 2
	for i in range(4): Signature.tick(pet,target)
	check(pet.hp == 60 and target.regen_turns == 0,"regen cannot persist indefinitely")
	# Same species ID in an old save now resolves to its redesigned entry.
	game.party = [game.creature(9),game.creature(107)]
	game.reserve = [game.creature(91)]
	game.active = 1
	game.save_game(false)
	game.party = [game.creature(0)]
	game.active = 0
	game.load_game()
	check(game.party[0].species == 9 and game.party[1].species == 107 and game.reserve[0].species == 91,"persistent species IDs remain compatible")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("SPECIES RESULT: %d checks, %d failures; %d skill names, %d unique profiles, %d effect families" % [checks,failures,skills.size(),profiles.size(),kinds.size()])
	quit(1 if failures else 0)
