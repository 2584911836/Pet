extends SceneTree
# End-to-end input driver. No health, levels, recruits, enemy, wins or objective mutation.
# Uses actual keyboard movement and GUI mouse clicks; speeds simulation time only.
var game
var started := 0
var encounters := 0
var actions := 0
var losses := 0
var clicks := 0
var failed := false

func _initialize() -> void:
	call_deferred("run")

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code,true)
	await process_frame
	key(code,false)
	await process_frame

func abort(text: String) -> void:
	if failed: return
	failed = true
	printerr("JOURNEY FAIL: "+text)

func timed_out() -> bool:
	return Time.get_ticks_msec()-started > 330000 or encounters > 500

func click(fragment: String) -> bool:
	var scope = game.modal if game.modal != null else game.buttons
	var chosen: Button
	for node in scope.find_children("*","Button",true,false):
		if not node.disabled and node.text.contains(fragment):
			chosen = node
			break
	if chosen == null:
		abort("button missing: "+fragment)
		return false
	chosen.grab_focus()
	await process_frame
	var parent: Node = chosen.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(chosen)
			break
		parent = parent.get_parent()
	await process_frame
	var point := chosen.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	clicks += 1
	return true

func close_story() -> void:
	if game.modal != null: await tap(KEY_ESCAPE)

func passable(point: Vector2i) -> bool:
	return game.is_land(point) and not point in game.obstacle_tiles() and point not in [Vector2i(2,5),Vector2i(3,4)]

func route(target: Vector2i) -> Array:
	var start: Vector2i = game.player
	var queue: Array = [start]
	var previous := {start:start}
	while not queue.is_empty():
		var point: Vector2i = queue.pop_front()
		if point == target: break
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = point+direction
			if previous.has(next) or not passable(next): continue
			previous[next] = point
			queue.append(next)
	if not previous.has(target): return []
	var path: Array = []
	var point := target
	while point != start:
		path.push_front(point)
		point = previous[point]
	return path

func walk_step(destination: Vector2i) -> void:
	var before: Vector2i = game.player
	var direction := destination-before
	var code: Key = KEY_A if direction.x < 0 else KEY_D if direction.x > 0 else KEY_W if direction.y < 0 else KEY_S
	var step_started := Time.get_ticks_msec()
	while game.player == before and game.mode == "explore" and game.modal == null:
		key(code,true)
		await process_frame
		key(code,false)
		await process_frame
		if Time.get_ticks_msec()-step_started > 2500:
			abort("blocked movement to "+str(destination))
			break

func battle() -> void:
	encounters += 1
	var turn := 0
	while game.mode == "battle" and not failed:
		if game.busy:
			await process_frame
			continue
		var p: Dictionary = game.party[game.active]
		var command := "攻击"
		if int(p.hp) < int(p.max_hp)*0.6 and game.salves > 0:
			command = "药草"
		elif not game.guardian_battle and not game.known.has(int(game.enemy.species)):
			if game.seals <= 0: command = "撤离"
			elif game.enemy.hp > game.enemy.max_hp*0.65 and game.focus > 0: command = "安抚"
			else: command = "捕捉伙伴"
		elif game.focus >= 2: command = str(game.SPECIES[int(p.species)].skill)
		if turn > 35: command = "撤离"
		if not await click(command): break
		actions += 1
		turn += 1
		await process_frame
	if game.message.contains("失去战斗能力"): losses += 1
	await close_story()

func walk_to(target: Vector2i) -> void:
	while game.player != target and not failed:
		if timed_out(): abort("journey time/encounter limit"); return
		if game.modal != null: await close_story()
		if game.mode == "battle": await battle(); continue
		var path := route(target)
		if path.is_empty(): abort("no path to "+str(target)); return
		await walk_step(path[0])

func camp() -> void:
	await walk_to(Vector2i(2,6))
	if failed: return
	await tap(KEY_E)
	await process_frame

func region(island: int, area: int) -> void:
	await close_story()
	var target := island*3+area
	while game.zone*3+game.area != target and not failed:
		var next: int = game.next_region_toward(target)
		if next < 0: abort("no unlocked regional road"); return
		var gate: Vector2i = game.region_exit_tile(next)
		var bounds: Vector2i = game.map_size()
		var inward := Vector2i.RIGHT if gate.x == 0 else Vector2i.LEFT if gate.x == bounds.x-1 else Vector2i.DOWN if gate.y == 0 else Vector2i.UP
		await walk_to(gate+inward)
		if failed: return
		await walk_step(gate)
		if game.zone*3+game.area != next: abort("physical region crossing failed"); return
		await process_frame

func gather_current_pool() -> void:
	var steps := 0
	while not failed:
		if timed_out(): abort("collection time/encounter limit"); return
		var missing := 0
		for id in game.encounter_pool():
			if not game.known.has(id): missing += 1
		if missing == 0: return
		if game.mode == "battle": await battle(); continue
		await close_story()
		var p: Dictionary = game.party[game.active]
		if game.seals <= 1 or int(p.hp) < int(p.max_hp)*0.45:
			await camp()
			if failed: return
		var best: Array = []
		for y in range(1,10):
			for x in range(1,17):
				var point := Vector2i(x,y)
				if point == game.player or not game.is_grass(point) or not passable(point): continue
				var path := route(point)
				if not path.is_empty() and (best.is_empty() or path.size() < best.size()): best = path
		if best.is_empty(): abort("no reachable grass"); return
		await walk_step(best[0])
		steps += 1
		if steps > 3000: abort("encounter starvation"); return

func run() -> void:
	started = Time.get_ticks_msec()
	Engine.time_scale = 10
	root.size = Vector2i(1152,720)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.rng.seed = 20261018
	await process_frame
	if not await click("开始新的旅程"): finish(); return
	if game.modal != null and game.modal_body.get_child(0).text == "新的旅程":
		if not await click("确认开始"): finish(); return
	await close_story()
	for island in range(3):
		for area in range(3):
			await region(island,area)
			if failed: break
			await gather_current_pool()
			print("JOURNEY region=%d/%d dex=%d battles=%d steps=%d" % [island,area,game.discovered(),encounters,game.steps_walked])
			if failed: break
		if failed: break
		await camp()
		await tap(KEY_R)
		if not await click("查看本地区生态委托"): break
		if not await click("领取观察奖励"): break
		await close_story()
		await region(island,0)
		await walk_to(Vector2i(15,2))
		if game.mode == "battle": await battle()
		await close_story()
		if not game.completed[island]: abort("regional license was not completed"); break
	if not failed:
		await region(2,2)
		await camp()
		await walk_to(Vector2i(15,2))
		if game.mode == "battle": await battle()
		await close_story()
		if not game.story_flags.get("parents_rescued",false): abort("parents were not rescued")
	if not failed:
		await region(2,0)
		await camp()
		await walk_to(Vector2i(15,2))
		if game.mode == "battle": await battle()
		await close_story()
		if not game.story_flags.get("champion",false): abort("championship was not completed")
	if not failed and (game.discovered() != 108 or game.completed.count(true) != 3 or game.keeper_rewards.count(true) != 3): abort("final objectives missing")
	print("JOURNEY RESULT: dex=%d/108 licenses=%d/3 quests=%d/3 battles=%d actions=%d steps=%d losses=%d clicks=%d elapsed_ms=%d rescued=%s champion=%s failed=%s" % [game.discovered(),game.completed.count(true),game.keeper_rewards.count(true),encounters,actions,game.steps_walked,losses,clicks,Time.get_ticks_msec()-started,str(game.story_flags.get("parents_rescued",false)),str(game.story_flags.get("champion",false)),str(failed)])
	await finish()

func finish() -> void:
	if game != null:
		game.audio.shutdown()
		await create_timer(2).timeout
		game.queue_free()
		await process_frame
	Engine.time_scale = 1
	quit(1 if failed else 0)
