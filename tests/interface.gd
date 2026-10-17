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
	check(game.player == Vector2i(3,5),"physical keyboard moves character")
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
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("UI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
