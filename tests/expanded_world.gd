extends SceneTree
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL EXPANDED: "+label)
func _initialize() -> void:
	call_deferred("run")
func reachable(target: Vector2i) -> bool:
	var queue := [game.player]
	var seen := {game.player:true}
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		if tile == target: return true
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = tile+delta
			if seen.has(next) or not game.is_land(next) or next in game.obstacle_tiles() or next in [Vector2i(2,5),Vector2i(3,4)] or game.exit_destination(next) >= 0: continue
			seen[next] = true
			queue.append(next)
	return false
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.animations_enabled = false
	game.new_game()
	game.close_modal()
	game.completed = [true,true,true]
	var sizes := {}
	var hud_position: Vector2 = game.info.position
	for node in range(9):
		game.visit_region(int(node/3),node%3)
		var bounds: Vector2i = game.map_size()
		sizes[bounds] = true
		check(bounds.x > 18 and bounds.y > 11,"real map area larger than legacy viewport")
		var cache: Vector2i = game.Layout.cache_tile(game.zone,game.area)
		check(reachable(cache),"expanded exploration reward reachable on actual terrain")
		check(not game.is_grass(cache),"cache itself is safe from random encounter")
		game.set_tracking("expedition")
		check(not game.guide_path.is_empty() and game.guide_path.back() == cache,"new route reaches distant cache")
		game.player = cache
		game.reset_visual_positions()
		game.refresh()
		var camera: Vector2 = game.camera_offset()
		check(camera.x > 0 and camera.y > 0,"camera follows exploration beyond original view")
		var local_hero: Vector2 = Vector2(game.player)*game.TILE+Vector2(20,20)-camera
		check(Rect2(Vector2.ZERO,Vector2(720,440)).has_point(local_hero),"tracked hero remains inside clipped world view")
		check(game.info.position == hud_position and game.world_view.clip_contents,"camera does not move HUD and world view clips content")
		check(camera.x <= bounds.x*40-720 and camera.y <= bounds.y*40-440,"camera clamped to map dimensions")
		game.save_game(false)
		game.player = Vector2i(2,6)
		game.load_game()
		check(game.player == cache and game.tracked_goal == "expedition","new map coordinates and tracking survive save")
		var seals: int = game.seals
		game.interact_nearby()
		check(game.story_flags.get("expedition_%d" % node,false) and game.seals == seals+3 and game.tracked_goal == "main","R grants optional cache once and returns main tracking")
		game.close_modal()
		game.inspect_expedition_cache()
		check(game.seals == seals+3,"reopening cache cannot duplicate rewards")
		game.close_modal()
		game.show_local_map()
		var chart = game.modal_body.get_child(2)
		check(chart.cell_size()*bounds.x <= 414.01 and chart.cell_size()*bounds.y <= 253.01,"whole-map chart fits panel")
		game.close_modal()
		game.player = Vector2i(bounds.x-2,bounds.y-2)
		game.reset_visual_positions()
		camera = game.camera_offset()
		check(camera == Vector2(bounds.x*40-720,bounds.y*40-440),"camera reaches far edge without showing outside map")
	check(sizes.size() == 9,"all nine areas use distinct dimensions")
	game.visit_region(0,0,Vector2i(10,5))
	game.save_game(false)
	game.player = Vector2i(20,15)
	game.load_game()
	check(game.player == Vector2i(10,5),"legacy in-core save location retained")
	game.player = Vector2i(2,6)
	var seals: int = game.seals
	game.inspect_expedition_cache()
	check(game.seals == seals,"remote cache claim rejected")
	game.mode = "battle"
	game.inspect_expedition_cache()
	check(game.seals == seals,"combat cache claim rejected")
	game.mode = "explore"
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("Expanded world: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
