extends SceneTree

var checks := 0
var failures := 0
var game

func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS UI: "+text)
	else:
		failures += 1
		printerr("FAIL UI: "+text)

func click(text: String) -> void:
	for child in game.modal_body.get_children():
		if child is Button and child.text == text:
			child.pressed.emit()
			return
	check(false,"missing button: "+text)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.modal != null,"title appears on launch")
	click("开始新的旅程")
	await process_frame
	check(FileAccess.file_exists(game.SAVE_PATH) and game.modal != null,"new game writes initial save and opens tutorial")
	click("让旅程继续")
	await process_frame
	check(game.modal == null and game.mode == "explore","tutorial continues into exploration")
	game.step_timer = 0
	key(KEY_D,true)
	await process_frame
	await process_frame
	key(KEY_D,false)
	check(game.player == Vector2i(3,6),"physical keyboard moves character")
	game.set_process(false)
	key(KEY_T,true)
	key(KEY_T,false)
	await process_frame
	check(game.tide == 1,"T key rings tidal bell")
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	await process_frame
	check(game.modal != null,"Escape opens travel menu")
	click("设置与操作说明")
	await process_frame
	for child in game.modal_body.get_children():
		if child is HSlider: child.value = 0.35
	var config := ConfigFile.new()
	check(config.load("user://settings.cfg") == OK and is_equal_approx(float(config.get_value("audio","volume",0)),0.35),"volume slider persists setting")
	click("返回旅程")
	check(game.modal == null,"settings returns to gameplay")
	game.start_battle(1)
	var original: int = game.enemy.hp
	game.turn("attack")
	var once: int = game.enemy.hp
	game.turn("attack")
	check(game.busy and once < original and game.enemy.hp == once,"double action during animation is ignored")
	await create_timer(0.5).timeout
	check(not game.busy and game.party[game.active].hp < game.party[game.active].max_hp,"enemy resolves after attack animation")
	game.turn("flee")
	check(game.mode == "explore","flee exits to exploration")
	game.show_title()
	click("开始新的旅程")
	await process_frame
	check(game.modal != null and game.modal_body.get_child(0).text == "新的潮汐","existing save requires overwrite confirmation")
	click("确认开始")
	check(FileAccess.file_exists(game.SAVE_PATH+".bak") and game.zone == 0,"new game backs up prior save")
	game.close_modal()
	game.zone = 0
	game.tide = 0
	game.player = game.relic_position(0)
	var seals_before: int = game.seals
	check(game.find_relic() and game.seals == seals_before+3,"tidal relic grants supplies")
	game.close_modal()
	check(not game.find_relic() and game.seals == seals_before+3,"relic cannot be farmed repeatedly")
	game.save_game(false)
	game.relics = [false,false,false,false,false,false]
	game.load_game()
	check(game.relics[0],"relic discovery persists through save")
	game.show_dex()
	var has_grid := false
	for child in game.modal_body.get_children():
		if child is GridContainer and child.get_child_count() == 9: has_grid = true
	check(has_grid,"dex displays nine paginated creature cards")
	# Real atlas textures are larger than cards: every page must constrain them.
	for page in range(12):
		game.dex_page = page
		game.show_dex()
		await process_frame
		await process_frame
		for child in game.modal_body.get_children():
			if child is GridContainer:
				for card in child.get_children():
					var portrait: TextureRect = card.get_node("Content/Portrait")
					var bounds := Rect2(Vector2.ZERO,card.size)
					var image_bounds := Rect2(portrait.global_position-card.global_position,portrait.size)
					check(bounds.encloses(image_bounds) and portrait.size.y > 50 and portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"dex portrait fits card on page %d" % (page+1))

	game.close_modal()
	game.completed = [true,true,true]
	game.visit_region(2,2)
	check(game.zone == 2 and game.area == 2,"world map visits ninth region")
	var pool: Array = game.encounter_pool()
	check(pool.size() >= 5,"current region has a populated encounter pool")
	game.save_game(false)
	game.area = 0
	game.load_game()
	check(game.area == 2,"region location persists")
	game.show_character()
	check(game.modal_body.get_child(0).text.contains("洛汐"),"protagonist profile opens")
	game.close_modal()
	game.animations_enabled = false
	game.party = [game.creature(0,99)]
	game.active = 0
	game.start_battle(107)
	game.enemy.hp = 1
	game.turn("soothe")
	check(game.enemy.hp == 1 and game.mode == "battle","soothe is nonlethal even with overlevelled companion")
	check(game.capture_chance() > 0.8,"low health exposes a high capture chance")
	game.turn("flee")
	game.visit_region(0,0)
	game.known = []
	for id in range(game.PET_COUNT):
		if int(game.SPECIES[id].island) == 0 and game.known.size() < 6: game.known.append(id)
	game.keeper_rewards = [false,false,false]
	game.start_battle(1)
	var chance_before: float = game.capture_chance()
	game.turn("flee")
	game.talk_keeper()
	check(game.modal_body.get_child(0).text.contains("阿岚"),"keeper dialogue opens at camp")
	game.show_keeper_quest()
	game.claim_keeper_reward()
	check(game.keeper_rewards[0] and game.seals >= 14,"ecology quest grants one-time reward")
	var supplied: int = game.seals
	game.claim_keeper_reward()
	check(game.seals == supplied,"quest reward cannot be claimed twice")
	game.close_modal()
	game.start_battle(1)
	check(is_equal_approx(game.capture_chance()-chance_before,0.02),"ecology quest adds permanent capture bonus")
	game.turn("flee")
	game.save_game(false)
	game.keeper_rewards = [false,false,false]
	game.load_game()
	check(game.keeper_rewards[0],"quest completion survives save/load")
	game.player = Vector2i(4,4)
	game.move_player(Vector2i(-1,0))
	check(game.modal != null and game.player == Vector2i(4,4),"bumping keeper from east starts conversation")
	game.close_modal()
	game.mode = "explore"
	game.area = 0
	game.player = Vector2i(2,6)
	game.party = [game.creature(0),game.creature(1),game.creature(2)]
	game.reserve = [game.creature(3)]
	game.active = 2
	game.show_backpack()
	await process_frame
	check(game.modal_body.get_node("BackpackGrid").get_child_count() == 3,"backpack displays individual party pets")
	game.backpack_transfer(false,0)
	check(game.party.size() == 2 and game.reserve.size() == 2 and game.active == 1 and game.party[game.active].species == 2,"deposit preserves active companion after index shift")
	game.backpack_transfer(true,0)
	check(game.party.size() == 3 and game.party[2].species == 3,"withdraw fills available party slot")
	game.backpack_select(2)
	check(game.active == 2,"backpack selects active companion")
	game.load_game()
	check(game.active == 2 and game.party[2].species == 3 and game.reserve.size() == 1,"backpack changes survive save and load")
	game.area = 1
	game.backpack_transfer(false,0)
	check(game.party.size() == 3,"storage transfer rejected outside camp region")
	game.area = 0
	game.party = [game.creature(0)]
	game.active = 0
	game.backpack_transfer(false,0)
	check(game.party.size() == 1,"cannot deposit final companion")
	game.party.append(game.creature(1))
	game.party[1].hp = 0
	game.backpack_transfer(false,0)
	check(game.party.size() == 2,"cannot deposit last conscious companion")
	game.backpack_select(1)
	check(game.active == 0,"cannot select fainted companion")
	game.party = []
	for id in range(6): game.party.append(game.creature(id))
	game.active = 2
	game.reserve = [game.creature(42)]
	game.backpack_transfer(true,0)
	check(game.party.size() == 6 and game.party[2].species == 42 and game.reserve[0].species == 2,"full party exchange conserves both pets")
	game.reserve = []
	for id in range(13): game.reserve.append(game.creature(id))
	game.show_backpack(true,2)
	await process_frame
	check(game.modal_body.get_node("BackpackGrid").get_child_count() == 1,"reserve backpack paginates partial final page")
	game.reserve = []
	game.show_backpack(true,20)
	check(game.modal_body.get_node("BackpackGrid").get_child_count() == 0,"empty reserve handles stale page without errors")
	game.party = [game.creature(0),game.creature(1)]
	game.active = 0
	game.reserve = []
	for id in range(200): game.reserve.append(game.creature(id % game.PET_COUNT))
	game.backpack_transfer(false,1)
	check(game.party.size() == 2 and game.reserve.size() == 200,"full reserve rejects deposit without losing pet")
	game.party = []
	for id in range(6):
		game.party.append(game.creature(id))
		if id > 0: game.party[id].hp = 0
	game.reserve = [game.creature(42)]
	game.reserve[0].hp = 0
	game.backpack_transfer(true,0)
	check(game.party[0].species == 0 and game.reserve[0].species == 42,"cannot exchange last conscious pet for fainted reserve")
	game.mode = "battle"
	game.backpack_transfer(false,0)
	game.backpack_select(1)
	check(game.party.size() == 6 and game.active == 0,"backpack actions cannot bypass battle turn rules")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("UI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
