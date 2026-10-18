extends SceneTree
var failures := 0
var checks := 0
var game
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL NAVIGATION: "+label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	for node in range(9):
		for neighbor in game.connected_regions(node):
			check(node in game.connected_regions(neighbor),"roads are bidirectional")
	var reached := [0]
	var cursor := 0
	while cursor < reached.size():
		for neighbor in game.connected_regions(reached[cursor]):
			if neighbor not in reached: reached.append(neighbor)
		cursor += 1
	check(reached.size() == 9,"graph connects all nine areas")
	game.show_world_map()
	var locked_chart = game.modal_body.get_child(2)
	check(locked_chart.get_child(3).disabled and not locked_chart.get_child(1).disabled,"map distinguishes locked regions and open neighbors")
	locked_chart.get_child(3).pressed.emit()
	check(game.zone == 0 and game.area == 0,"locked node callback cannot bypass gate")
	game.close_modal()
	check(not game.fast_travel_unlocked(),"teleport starts locked")
	check(not game.can_navigate_region(1,0),"regional qualification gate")
	game.completed = [true,false,false]
	check(not game.can_navigate_region(1,0),"cannot skip connecting road")
	game.party[0].hp = 1
	game.navigate_region(0,2)
	check(game.zone == 0 and game.area == 2 and game.party[0].hp == 1,"walk to road without free healing")
	check(game.can_navigate_region(1,0),"road connects next town")
	game.navigate_region(1,0)
	check(game.zone == 1 and game.area == 0,"cross regional bridge")
	game.navigate_region(0,0)
	check(game.zone == 1,"reject nonadjacent destination")
	game.navigate_region(0,2)
	check(game.zone == 0 and game.area == 2,"bridge supports return journey")
	game.completed = [false,true,true]
	check(not game.region_unlocked(2) and not game.fast_travel_unlocked(),"inconsistent flags cannot bypass prerequisite")
	game.completed = [true,true,true]
	check(game.fast_travel_unlocked(),"three qualifications unlock teleport")
	for z in range(3):
		for a in range(3):
			if game.zone == z and game.area == a: continue
			game.navigate_region(z,a)
			check(game.zone == z and game.area == a,"teleport reaches every node")
	game.show_world_map()
	var chart = game.modal_body.get_child(2)
	check(chart.get_child_count() == 9,"map contains nine clickable nodes")
	var destination: int = (game.zone*3+game.area+1)%9
	chart.get_child(destination).pressed.emit()
	check(game.zone*3+game.area == destination and game.modal == null,"map click travels and closes overlay")
	game.save_game(false)
	game.completed = [false,false,false]
	game.load_game()
	check(game.fast_travel_unlocked(),"teleport unlock persists through existing save")
	game.start_battle(2)
	var old: int = game.zone*3+game.area
	game.navigate_region(0,0)
	check(game.zone*3+game.area == old,"no teleport during combat")
	game.mode = "explore"
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("Navigation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
