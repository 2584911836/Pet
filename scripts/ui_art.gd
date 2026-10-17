extends Control
var completed: Array = [false,false,false]
var current := 0
const WorldArt = preload("res://scripts/world_art.gd")

func _draw() -> void:
	var centers := [Vector2(105,85),Vector2(325,62),Vector2(550,90)]
	draw_rect(Rect2(0,0,660,165),Color("203e50"))
	for i in range(2): draw_dashed_line(centers[i],centers[i+1],Color("9ac7c2"),2,7)
	for i in range(3):
		var center: Vector2 = centers[i]
		var points := PackedVector2Array([Vector2(-48,-13),Vector2(-32,-31),Vector2(-8,-34),Vector2(12,-27),Vector2(37,-22),Vector2(47,2),Vector2(28,24),Vector2(2,30),Vector2(-27,22)])
		var sand := PackedVector2Array()
		var land := PackedVector2Array()
		for point in points:
			sand.append(center+point)
			land.append(center+point*0.85-Vector2(0,3))
		draw_colored_polygon(sand,Color("bcaf8a"))
		draw_colored_polygon(land,Color("648b70"))
		for j in range(2): WorldArt.draw_object(self,0,center+Vector2(-23+j*19,8),Vector2(24,32))
		WorldArt.draw_object(self,4,center+Vector2(20,13),Vector2(24,42),Color.WHITE if completed[i] else Color(0.65,0.77,0.87))
		WorldArt.draw_object(self,2,center+Vector2(-15,28),Vector2(18,13))
		if i == current: draw_arc(center,53,0,TAU,40,Color("f7dba1"),2)
		var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
		draw_string(font,center+Vector2(-38,55),["微光岛","雾钟湾","星落屿"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("efe4c3"))
