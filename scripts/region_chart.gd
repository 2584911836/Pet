extends Control
var game
const POINTS = [Vector2(100,65),Vector2(100,155),Vector2(100,245),Vector2(330,65),Vector2(330,155),Vector2(330,245),Vector2(560,65),Vector2(560,155),Vector2(560,245)]

func build_nodes() -> void:
	for node in range(9):
		var z: int = node / 3
		var a: int = node % 3
		var button := Button.new()
		button.position = POINTS[node]-Vector2(84,27)
		button.size = Vector2(168,54)
		var current: bool = game.zone == z and game.area == a
		var unlocked: bool = game.region_unlocked(z)
		var available: bool = game.can_navigate_region(z,a)
		var status := "当前位置" if current else "资格锁定" if not unlocked else "传送" if game.fast_travel_unlocked() else "沿路前往" if available else "经相邻节点抵达"
		button.text = str(game.AREAS[z][a])+"\n"+status
		button.disabled = not available
		button.tooltip_text = "本区域有 12 种伙伴；通行不会恢复队伍生命。\n"+status
		button.pressed.connect(game.navigate_region.bind(z,a))
		add_child(button)

func _draw() -> void:
	if not is_instance_valid(game): return
	draw_style_box(_background(),Rect2(Vector2.ZERO,Vector2(660,300)))
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	for z in range(3):
		draw_string(font,Vector2(16+230*z,22),str(game.ISLANDS[z].name),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e8dbad"))
	for edge in game.REGION_EDGES:
		var start: Vector2 = POINTS[edge[0]]
		var finish: Vector2 = POINTS[edge[1]]
		# Local town-to-road shortcut bends beside the forest node.
		var points := [start,finish]
		if edge[1]-edge[0] == 2:
			points = [start,start+Vector2(99,0),finish+Vector2(99,0),finish]
		var opened: bool = game.region_unlocked(int(edge[0]/3)) and game.region_unlocked(int(edge[1]/3))
		for i in range(points.size()-1):
			if opened: draw_line(points[i],points[i+1],Color("88c8af"),3,true)
			else: draw_dashed_line(points[i],points[i+1],Color("64717b"),2,7)
	var current: int = game.zone*3+game.area
	draw_rect(Rect2(POINTS[current]-Vector2(87,30),Vector2(174,60)),Color("ffdb8a"),false,3)

func _background() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("20363e")
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	return box
