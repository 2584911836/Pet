extends RefCounted
# Nine deterministic environments; collisions and both maps use the same terrain.
const TILE := 40.0
const PALETTES = [
	["83a477","658c62","cfbd91","477f8c"], ["61845a","416b47","b7a783","386f78"], ["9ca47b","79885b","bfae88","518892"],
	["b3916e","876e54","d1b28b","456875"], ["927b68","6e6052","b99872","334f61"], ["a99877","7c7d61","d0bd91","4d7b83"],
	["7d96a6","5f788e","bfc4b6","42677e"], ["728b82","4e6b66","b8bb9c","3b6575"], ["7c899a","596778","b5b5a7","354d67"]]
const FEATURES = ["青芽广场 · 花圃与民居","曙光林 · 林池与古树","溪谷驿道 · 河湾与木栈桥","赤岩集镇 · 红瓦与石阶","琥珀矿径 · 矿池与轨道","货运栈道 · 堆场与路标","联赛中心 · 星纹广场","星冠林 · 银叶与夜池","研究站外围 · 围栏与温室"]

static func corridor(p: Vector2i) -> bool:
	return p.y == 5 or p.x == 11 or (p.x == 15 and p.y <= 5)

static func protected_tile(p: Vector2i) -> bool:
	return corridor(p) or p.distance_to(Vector2i(2,5)) <= 2 or p.distance_to(Vector2i(3,4)) <= 1 or p.distance_to(Vector2i(3,6)) <= 1 or p.distance_to(Vector2i(7,4)) <= 1

static func water(zone: int, area: int, p: Vector2i) -> bool:
	if protected_tile(p): return false
	if zone == 1 and area == 1 and p.y == 2 and p.x >= 6 and p.x <= 9: return false
	var supplies := [[Vector2i(7,2),Vector2i(14,8)],[Vector2i(6,8),Vector2i(13,1)],[Vector2i(6,3),Vector2i(14,7)]]
	if area == 0 and p in supplies[zone]: return false
	var rectangles := [Rect2i(6,7,4,2),Rect2i(6,1,4,3),Rect2i(12,7,4,2),Rect2i(6,7,4,2),Rect2i(5,1,5,3),Rect2i(12,7,4,2),Rect2i(6,7,4,2),Rect2i(5,1,5,3),Rect2i(12,7,4,2)]
	return rectangles[zone*3+area].has_point(p)

static func path_tile(zone: int, area: int, p: Vector2i) -> bool:
	if corridor(p): return true
	if zone == 1 and area == 1 and p.y == 2 and p.x >= 6 and p.x <= 9: return true
	if area == 0: return Rect2i(4,4,9,3).has_point(p) or (p.y == 7 and p.x <= 5)
	if area == 1: return (p.x == 4 and p.y >= 5) or (p.y == 8 and p.x <= 11)
	return p.y == 3 and p.x >= 4 or p.x == 4 and p.y >= 3 and p.y <= 5

static func ground(canvas: CanvasItem, game) -> void:
	var colors: Array = PALETTES[game.zone*3+game.area]
	for y in range(11):
		for x in range(18):
			var p := Vector2i(x,y)
			var origin: Vector2 = game.ORIGIN+Vector2(p)*TILE
			var pond := water(game.zone,game.area,p)
			var land: bool = game.is_land(p)
			var path := path_tile(game.zone,game.area,p)
			var color := Color(colors[3]) if pond else Color(colors[2]) if land and path else Color(colors[1]) if game.is_grass(p) and land else Color(colors[0]) if land else Color(colors[1]).darkened(0.4)
			var variation: float = ((x*17+y*31+game.zone*7+game.area*13)%7-3)*0.009
			canvas.draw_rect(Rect2(origin,Vector2(TILE,TILE)),color.lightened(variation))
			if pond:
				var wave := 0.0 if game.reduce_motion else sin(game.walk_time*1.4+x+y)*2
				canvas.draw_line(origin+Vector2(7,14+wave),origin+Vector2(28,14+wave),Color("8fc7c5"),1)
				canvas.draw_line(origin+Vector2(20,29-wave),origin+Vector2(34,29-wave),Color("659ca6"),1)
				for delta in [Vector2i.LEFT,Vector2i.UP]:
					if not water(game.zone,game.area,p+delta):
						canvas.draw_line(origin,origin+(Vector2(0,40) if delta == Vector2i.LEFT else Vector2(40,0)),Color(colors[2]),3)
			elif land and path:
				if game.area == 0:
					canvas.draw_line(origin+Vector2(0,39),origin+Vector2(40,39),color.darkened(0.13),1)
					canvas.draw_line(origin+Vector2(20*(y%2),0),origin+Vector2(20*(y%2),40),color.darkened(0.1),1)
				elif game.area == 2 and x >= 11:
					for plank in range(4): canvas.draw_line(origin+Vector2(0,plank*10),origin+Vector2(40,plank*10),color.darkened(0.2),1)
				else:
					canvas.draw_circle(origin+Vector2(7+(x*7)%28,12+(y*9)%20),2,color.darkened(0.12))
			elif land and game.is_grass(p):
				game.WorldArt.draw_object(canvas,1,origin+Vector2(20,39),Vector2(36,28),Color("b4c8a4") if game.zone == 2 else Color.WHITE)
			else:
				for i in range(3):
					var seed := x*13+y*19+i*37
					canvas.draw_rect(Rect2(origin+Vector2(4+seed%30,6+(seed*3)%27),Vector2(3,2)),color.lightened(0.12))
	# Bridge rails and cross-road details provide visible destinations.
	for x in range(12,17):
		if game.area == 2:
			canvas.draw_line(game.ORIGIN+Vector2(x*40,205),game.ORIGIN+Vector2((x+1)*40,205),Color("675c48"),3)
			canvas.draw_line(game.ORIGIN+Vector2(x*40,235),game.ORIGIN+Vector2((x+1)*40,235),Color("675c48"),3)
	if game.area == 0:
		var center: Vector2 = game.ORIGIN+Vector2(8,5)*40+Vector2(20,20)
		canvas.draw_arc(center,46,0,TAU,36,Color(colors[0]).lightened(0.25),3)
		canvas.draw_arc(center,37,0,TAU,36,Color(colors[1]),2)

static func buildings(canvas: CanvasItem, game) -> void:
	var roof_colors := [Color("8a6258"),Color("ad6553"),Color("65748d")]
	if game.area == 0:
		for tile in [Vector2i(5,2),Vector2i(9,2),Vector2i(5,8)]:
			house(canvas,game.ORIGIN+Vector2(tile)*40,roof_colors[game.zone],game.zone)
	elif game.zone == 1 and game.area == 1:
		var base: Vector2 = game.ORIGIN+Vector2(6,2)*40
		canvas.draw_rect(Rect2(base,Vector2(125,18)),Color("3a363c"))
		for x in range(6): canvas.draw_rect(Rect2(base+Vector2(x*22,-4),Vector2(6,26)),Color("aa8761"))
		for y in [0,15]: canvas.draw_line(base+Vector2(0,y),base+Vector2(125,y),Color("a7abb0"),2)
		canvas.draw_rect(Rect2(base+Vector2(45,-14),Vector2(29,25)),Color("655b56"))
	elif game.zone == 2 and game.area == 2:
		house(canvas,game.ORIGIN+Vector2(8,2)*40,Color("63878b"),2)
		for x in range(5,11):
			var base: Vector2 = game.ORIGIN+Vector2(x,8)*40
			canvas.draw_rect(Rect2(base+Vector2(0,6),Vector2(40,4)),Color("849b9f"))
			canvas.draw_rect(Rect2(base+Vector2(3,-8),Vector2(4,30)),Color("adc1bd"))
	else:
		# Rest pavilion / trail supply stall; decorative and off the travel routes.
		var base: Vector2 = game.ORIGIN+Vector2(9,8)*40
		canvas.draw_rect(Rect2(base+Vector2(-19,-8),Vector2(38,30)),Color("75634b"))
		canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-29,-8),base+Vector2(0,-35),base+Vector2(29,-8)]),Color("748677") if game.zone != 1 else Color("aa7758"))

static func house(canvas: CanvasItem, origin: Vector2, roof: Color, zone: int) -> void:
	canvas.draw_rect(Rect2(origin+Vector2(-34,17),Vector2(80,13)),Color(0.08,0.14,0.17,0.25))
	canvas.draw_rect(Rect2(origin+Vector2(-29,-24),Vector2(62,48)),Color("e2d4b2") if zone != 2 else Color("c0cbd0"))
	canvas.draw_rect(Rect2(origin+Vector2(-33,-24),Vector2(70,5)),roof.darkened(0.3))
	canvas.draw_colored_polygon(PackedVector2Array([origin+Vector2(-38,-26),origin+Vector2(2,-56),origin+Vector2(42,-26)]),roof)
	for y in range(3): canvas.draw_line(origin+Vector2(-29+y*10,-31-y*8),origin+Vector2(33-y*10,-31-y*8),roof.lightened(0.12),1)
	canvas.draw_rect(Rect2(origin+Vector2(-3,0),Vector2(17,24)),Color("536c70"))
	for x in [-21,20]:
		canvas.draw_rect(Rect2(origin+Vector2(x,-9),Vector2(11,13)),Color("729a9c"))
		canvas.draw_rect(Rect2(origin+Vector2(x+2,-7),Vector2(7,9)),Color("ead5a0"))

static func structure_tiles(zone: int, area: int) -> Array:
	var tiles := []
	if area == 0:
		for base in [Vector2i(5,2),Vector2i(9,2),Vector2i(5,8)]:
			for dx in [-1,0]:
				for dy in [-1,0]: tiles.append(base+Vector2i(dx,dy))
	elif zone == 2 and area == 2:
		tiles = [Vector2i(7,1),Vector2i(8,1),Vector2i(7,2),Vector2i(8,2)]
	elif not (zone == 1 and area == 1):
		tiles = [Vector2i(8,7),Vector2i(9,7),Vector2i(8,8),Vector2i(9,8)]
	return tiles

static func landmark(canvas: CanvasItem, game) -> void:
	var base: Vector2 = game.ORIGIN+Vector2(15,2)*40
	var accent := Color("a1be88") if game.zone == 0 else Color("cc9775") if game.zone == 1 else Color("9ab8d0")
	canvas.draw_rect(Rect2(base+Vector2(-27,35),Vector2(94,12)),Color("8d9586"))
	canvas.draw_rect(Rect2(base+Vector2(-22,28),Vector2(84,9)),Color("b3b39b"))
	canvas.draw_rect(Rect2(base+Vector2(-24,-18),Vector2(88,49)),Color("cdd3c2"))
	if game.area == 0:
		canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-35,-18),base+Vector2(20,-50),base+Vector2(75,-18)]),accent.darkened(0.2))
		for x in [-19,48]:
			canvas.draw_rect(Rect2(base+Vector2(x,-13),Vector2(10,45)),Color("ece6ca"))
			canvas.draw_rect(Rect2(base+Vector2(x-3,-16),Vector2(16,5)),Color("d4c9a8"))
		canvas.draw_arc(base+Vector2(20,10),15,PI,TAU,20,Color("536977"),5)
		canvas.draw_rect(Rect2(base+Vector2(5,10),Vector2(30,22)),Color("536977"))
		canvas.draw_circle(base+Vector2(20,-23),7,Color("e1cc87"))
		canvas.draw_line(base+Vector2(20,-29),base+Vector2(20,-17),accent.darkened(0.3),2)
	elif game.zone == 2 and game.area == 2:
		canvas.draw_rect(Rect2(base+Vector2(-29,-24),Vector2(98,10)),Color("486b78"))
		canvas.draw_rect(Rect2(base+Vector2(-15,-8),Vector2(26,18)),Color("71a7b0"))
		canvas.draw_line(base+Vector2(-2,-8),base+Vector2(-2,10),Color("c7e6d7"),2)
		canvas.draw_rect(Rect2(base+Vector2(22,-8),Vector2(25,40)),Color("3a5768"))
		canvas.draw_circle(base+Vector2(54,3),4,Color("b8dda5") if game.story_flags.get("parents_rescued",false) else Color("df9284"))
	else:
		canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-33,-19),base+Vector2(20,-47),base+Vector2(72,-19)]),accent.darkened(0.25))
		canvas.draw_rect(Rect2(base+Vector2(9,3),Vector2(24,29)),Color("53635f"))
		for x in [-13,43]: canvas.draw_rect(Rect2(base+Vector2(x,-3),Vector2(13,16)),Color("94bfc0"))
	for x in [-39,75]:
		canvas.draw_line(base+Vector2(x,30),base+Vector2(x,-34),Color("c4c4a8"),2)
		canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(x,-34),base+Vector2(x+15,-28),base+Vector2(x,-20)]),accent)
