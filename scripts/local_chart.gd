extends Control
var game
const OFFSET := Vector2(10,10)
var cell := 12.0
var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
func marker(tile: Vector2i, text: String, color: Color) -> void:
	var p := OFFSET+(Vector2(tile)+Vector2(0.5,0.5))*cell
	draw_circle(p,minf(8,cell*0.4),color)
	draw_string(font,p+Vector2(-cell*0.27,cell*0.27),text,HORIZONTAL_ALIGNMENT_LEFT,-1,clampi(int(cell*0.65),8,13),Color("182e3b"))
func cell_size() -> float:
	var bounds: Vector2i = game.map_size()
	return minf(414.0/bounds.x,253.0/bounds.y)

func _draw() -> void:
	if not is_instance_valid(game): return
	var bounds: Vector2i = game.map_size()
	cell = cell_size()
	var obstacles: Array = game.obstacle_tiles()
	for y in range(bounds.y):
		for x in range(bounds.x):
			var tile := Vector2i(x,y)
			var color := Color("33463e") if not game.is_land(tile) else Color("537d61") if game.is_grass(tile) else Color("c0b08a")
			if game.Layout.water(game.zone,game.area,tile): color = Color("3b7887")
			if tile in obstacles: color = Color("354c45")
			draw_rect(Rect2(OFFSET+Vector2(tile)*cell,Vector2(cell-0.6,cell-0.6)),color)
	var view_origin: Vector2 = game.camera_offset()/game.TILE
	draw_rect(Rect2(OFFSET+view_origin*cell,Vector2(18,11)*cell),Color("e7ddb7"),false,1.5)
	for destination in game.connected_regions(game.zone*3+game.area): marker(game.region_exit_tile(destination),"出",Color("f7db98") if game.region_unlocked(int(destination/3)) else Color("d49086"))
	var survey_index: int = game.zone*3+game.area
	marker(game.Surveys.POINTS[survey_index].tile,"查",Color("b79bd3") if game.story_flags.get(game.Surveys.key(survey_index),false) else Color("ecd09a"))
	marker(game.Layout.cache_tile(game.zone,game.area),"补",Color("aebca9") if game.story_flags.get("expedition_%d" % survey_index,false) else Color("f4b884"))
	for tile in game.guide_path: draw_circle(OFFSET+(Vector2(tile)+Vector2(0.5,0.5))*cell,1.3,Color("ffe6a1"))
	marker(Vector2i(15,2),"赛" if game.area == 0 else "站",Color("bce9e1"))
	marker(Vector2i(2,5),"营",Color("fff1d2"))
	marker(Vector2i(3,4),"岚",Color("a5c8e9"))
	if game.area > 0: marker(game.field_npc_position(),"人",Color("e4bbdf"))
	marker(game.player,"你",Color("f7db98"))
	draw_string(font,Vector2(444,32),"全区地图 %d×%d" % [bounds.x,bounds.y],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("f3dca3"))
	var labels := ["白框：当前镜头视野","金点：追踪路线","绿色草地 / 蓝色水域","金色出口 / 红色锁定","查：调查线索  补：补给","J：主线与调查日志","R：交谈或调查地点"]
	for i in range(labels.size()): draw_string(font,Vector2(444,67+i*27),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("d8e7e1"))
