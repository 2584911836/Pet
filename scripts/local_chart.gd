extends Control
var game
const CELL = 23.0
const OFFSET = Vector2(10,10)
func _draw() -> void:
	if not is_instance_valid(game): return
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	for y in range(11):
		for x in range(18):
			var tile := Vector2i(x,y)
			var color := Color("33463e") if not game.is_land(tile) else Color("537d61") if game.is_grass(tile) else Color("c0b08a")
			if game.Layout.water(game.zone,game.area,tile): color = Color("3b7887")
			if tile in game.obstacle_tiles(): color = Color("354c45")
			draw_rect(Rect2(OFFSET+Vector2(tile)*CELL,Vector2(CELL-1,CELL-1)),color)
	for destination in game.connected_regions(game.zone*3+game.area):
		var tile: Vector2i = game.region_exit_tile(destination)
		var p := OFFSET+(Vector2(tile)+Vector2(0.5,0.5))*CELL
		var color := Color("f7db98") if game.region_unlocked(int(destination/3)) else Color("d49086")
		draw_rect(Rect2(p-Vector2(10,10),Vector2(20,20)),color)
		draw_string(font,p+Vector2(-6,5),"出",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("182e3b"))
	for tile in game.guide_path: draw_circle(OFFSET+(Vector2(tile)+Vector2(0.5,0.5))*CELL,2,Color("ffe6a1"))
	for marker in [[game.player,"你",Color("f7db98")],[Vector2i(15,2),"赛" if game.area == 0 else "站",Color("bce9e1")],[Vector2i(2,5),"营",Color("fff1d2")],[Vector2i(3,4),"岚",Color("a5c8e9")]]:
		var p := OFFSET+(Vector2(marker[0])+Vector2(0.5,0.5))*CELL
		draw_circle(p,9,marker[2])
		draw_string(font,p+Vector2(-6,5),marker[1],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("182e3b"))
	if game.area > 0:
		var p := OFFSET+(Vector2(game.field_npc_position())+Vector2(0.5,0.5))*CELL
		draw_circle(p,9,Color("e4bbdf"))
		draw_string(font,p+Vector2(-6,5),"人",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("182e3b"))
	draw_string(font,Vector2(444,45),"本区地形",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f3dca3"))
	var labels := ["金点：追踪路线","绿色：遭遇草丛","蓝色：不可通行水域","金色出口：直接步行","红色出口：资格锁定","J：主线与委托日志","R：与身边的人交谈"]
	for i in range(labels.size()): draw_string(font,Vector2(444,80+i*27),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d8e7e1"))
