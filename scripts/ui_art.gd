extends Control
var completed: Array = [false,false,false]
var current := 0

func _draw() -> void:
	var centers := [Vector2(105,85),Vector2(325,62),Vector2(550,90)]
	draw_rect(Rect2(0,0,660,165),Color("203e50"))
	for i in range(2): draw_dashed_line(centers[i],centers[i+1],Color("9ac7c2"),2,7)
	for i in range(3):
		var center: Vector2 = centers[i]
		draw_rect(Rect2(center-Vector2(47,23),Vector2(94,46)),Color("b8ad8c"))
		draw_rect(Rect2(center-Vector2(36,32),Vector2(72,61)),Color("648b70"))
		for j in range(3): draw_rect(Rect2(center+Vector2(-28+j*19,-14),Vector2(11,13)),Color("3f6556"))
		draw_rect(Rect2(center+Vector2(10,-34),Vector2(12,32)),Color("cfdbc6"))
		draw_rect(Rect2(center+Vector2(7,-39),Vector2(18,7)),Color("f4dba2") if completed[i] else Color("778e9a"))
		if i == current: draw_rect(Rect2(center-Vector2(52,38),Vector2(104,75)),Color("f7dba1"),false,2)
		var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
		draw_string(font,center+Vector2(-38,55),["微光岛","雾钟湾","星落屿"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("efe4c3"))
