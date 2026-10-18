extends SceneTree
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL WALK: "+label)
func _initialize() -> void:
	call_deferred("run")
func route(target: Vector2i) -> Array:
	var queue := [game.player]
	var previous := {game.player:game.player}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == target:
			var result := []
			while current != game.player:
				result.push_front(current)
				current = previous[current]
			return result
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var tile: Vector2i = current+delta
			if previous.has(tile) or not game.is_land(tile) or tile in game.obstacle_tiles() or tile in [Vector2i(2,5),Vector2i(3,4)]: continue
			if game.exit_destination(tile) >= 0 and tile != target: continue
			previous[tile] = current
			queue.append(tile)
	return []
func walk_to(target: Vector2i) -> void:
	var path := route(target)
	check(not path.is_empty() or game.player == target,"target reachable from arrival")
	for tile in path:
		if tile == target and game.exit_destination(tile) >= 0: game.party[0].hp = 1
		game.move_player(tile-game.player)
		if game.mode == "battle": game.turn("flee")
		game.close_modal()
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	game.visit_region(0,2)
	walk_to(Vector2i(16,5))
	game.move_player(Vector2i.RIGHT)
	check(game.zone == 0 and game.area == 2 and game.player == Vector2i(16,5),"locked border blocks walking")
	game.completed = [true,false,false]
	game.visit_region(0,0)
	game.update_guide()
	check(game.guide_path.back() == game.region_exit_tile(2),"main guide leads to real connecting road")
	game.completed = [true,true,true]
	# Every directed edge is physically traversed; no map-menu navigation.
	for node in range(9):
		game.visit_region(int(node/3),node%3)
		for neighbor in game.connected_regions(node):
			var exit: Vector2i = game.region_exit_tile(neighbor)
			game.party[0].hp = 1
			walk_to(exit)
			check(game.zone*3+game.area == neighbor,"walking crosses correct graph edge")
			check(game.is_land(game.player) and game.player not in game.obstacle_tiles(),"arrival is walkable")
			check(game.party[0].hp == 1,"foot crossing does not heal")
			var return_exit: Vector2i = game.region_exit_tile(node)
			check(game.player.distance_to(return_exit) == 1,"reciprocal gate adjacent to arrival")
			game.move_player(return_exit-game.player)
			check(game.zone*3+game.area == node,"walking back returns through same road")
		game.player = Vector2i(2,6)
		for landmark in [Vector2i(15,3),Vector2i(3,5),Vector2i(11,1),Vector2i(11,9)]:
			check(not route(landmark).is_empty(),"landmarks and road corridors remain accessible")
		if game.area > 0:
			check(not route(game.field_npc_position()+Vector2i.RIGHT).is_empty(),"local NPC accessible")
	var current_node: int = game.zone*3+game.area
	game.cross_region_exit((current_node+4)%9)
	check(game.zone*3+game.area == current_node,"foot gate rejects nonadjacent destinations even after teleport unlock")
	game.party[0] = game.creature(0,6)
	game.party[0].xp = 3
	check(game.valid_creature(game.party[0]),"higher-level XP uses new staged save bounds")
	game.save_game(false)
	var before: Vector2i = game.player
	game.load_game()
	check(game.player == before,"new terrain position survives save")
	check(game.party[0].level == 6 and game.party[0].xp == 3,"level and expanded XP survive save")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("Walking world: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
