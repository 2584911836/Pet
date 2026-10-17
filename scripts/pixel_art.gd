extends RefCounted
# Original hand-authored pixel silhouettes. Characters map to a per-species palette.
const PATTERNS = [
[
"          ll            ",
"         lLLl           ",
"      ll lLLl ll        ",
"     lLLllLLllLLl       ",
"      lLLLLLLLLl        ",
"         sss            ",
"      oooooooo          ",
"    ooHHHHHHHooo        ",
"   oHHHHHHHHHHHHoo      ",
"  oHHHHHHHHHHHHHHHo     ",
"  oHHHeHHHHHeHHHHHo     ",
" ooHHHeHHHHHeHHHHHoo    ",
" oHHHHHHnnnHHHHHHHHo    ",
" oHHHHHHnnnHHHHHHHHo    ",
" oHHHHhHHHHHHhHHHHHo    ",
"  oHHhHHHHHHHHhHHHo     ",
"  ooHHHHHHHHHHHHoo      ",
"   oHHHHHHHHHHHHo       ",
"   oHHHo    oHHHo       ",
"   oooo      oooo       "
],
[
"    oo        oo        ",
"   oHHo      oHHo       ",
"   oHpHo    oHpHo       ",
"   oHppHo  oHppHo       ",
"    oHHHooooHHHo        ",
"    oHHHHHHHHHHo        ",
"   oHHHHHHHHHHHHo       ",
"   oHeHHHHHHHeHHo       ",
"   oHeHHHHHHHeHHo       ",
"    oHHHHnHHHHHo        ",
"     oHHnnnHHHo         ",
"    ooHHhhhHHoo     oo  ",
"   oHHHHhhhHHHHo   oww o",
"   oHHHHhhhHHHHo  owwwo ",
"   oHHHHhhhHHHHo owwwHo ",
"   oHHHHHHHHHHHooHHHHo ",
"    oHHHHHHHHHHHHHHHo  ",
"    oHHHHHHHHHHHHHoo   ",
"    oHHHo  oHHHooo     ",
"    oooo    oooo       "
],
[
"           www          ",
"          wHHHw         ",
"      oooooHHooooo      ",
"    ooHHHHHHHHHHHoo     ",
"   oHHHHHHHHHHHHHHHo    ",
"   oHHHeHHHHHHeHHHHo    ",
"  oHHHHeHHHHHHeHHHHHo   ",
"  oHHHHHHHHHHHHHHHHHo   ",
"   oHHHHHnnnnHHHHHHo    ",
"oo  oHHHHHHHHHHHHHo  oo ",
"oHooHHHHHhhhhHHHHHHooHo ",
"oHHHHHHHhhhhhhHHHHHHHHo ",
" oHHHHHHhhhhhhHHHHHHHo  ",
"  ooHHHHHhhhhHHHHHHoo   ",
"    oHHHHHHHHHHHHHo     ",
"    oHHHHHHHHHHHHHo oo  ",
"   ooHHHHHHHHHHHHHooHHo ",
"  oHHHooHHHHHooHHHHHHo  ",
"   ooo  ooooo  oooooo   "
],
[
"     ll         ll      ",
"   llLl         lLll    ",
"    lLLl       lLLl     ",
"     lLLl     lLLl      ",
"  ll  lLLl   lLLl  ll   ",
"  lLl  lLLlolLLl  lLl   ",
"   lLLloHHHHHHHolLLl    ",
"     ooHHHHHHHHHoo      ",
"    oHHHeHHHeHHHHHo     ",
"     oHHHHHHHHHHHo      ",
"      oHHHnnHHHHo       ",
"       oHHHHHHHo        ",
"     oooHHHHHHoooo      ",
"    oHHHHHHHHHHHHHo     ",
"   oHHHhhHHHHHhhHHHo    ",
"   oHHHHHHHHHHHHHHHo    ",
"    ooHHHHHHHHHHHoo     ",
"     oHHo oHHo oHHo     ",
"     oHHo oHHo oHHo     ",
"     oooo oooo oooo     "
],
[
"  oo               oo   ",
" oHHo             oHHo  ",
"oHHHHo           oHHHHo ",
"oHHooHo         oHooHHo ",
" oHHoHo  ooooo  oHoHHo  ",
"  oHHHo ooHHHoo oHHHo   ",
"   oHo oHHHHHHHo oHo    ",
"   oHooHHHeHeHHHooHo    ",
"    oHHHHHeHeHHHHHo     ",
"   oHHHHHHHHHHHHHHHo    ",
"  oHHHhhhhhhhhhhhHHHo   ",
"  oHHhhhhhhhhhhhhhHHo   ",
"  oHHHHHHHHHHHHHHHHHo   ",
" ooHHHHHHHHHHHHHHHHHoo  ",
"oHHooHHHHHHHHHHHHHooHHo ",
"ooo  ooHHHHHHHHHoo  ooo ",
" ooHoo oooooooo ooHoo   ",
" ooo             ooo    "
],
[
"               www      ",
"              wHHHw     ",
"               www      ",
"           oo           ",
"        oooHHoooo       ",
"      ooHHHHHHHHHoo     ",
"    ooHHHHHHHHHHHHHoo   ",
"   oHHHHHHHHHHHHHHHHHo  ",
"  oHHHHeHHHHHHHHHHHHHoo ",
"  oHHHHeHHHHHHHHHHHHHHHo",
"  oHHHHHHHHHHHHHHHHHHHHo",
"   oHHHHHHHHHHHHHHHHHHo ",
"    oHHHHhhhhhhhhHHHHo  ",
"   ooHHHhhhhhhhhHHHHoo  ",
"  oHHHooooHHHHHHooooHHo ",
"   ooo    oooooo    ooo ",
"                  oo    ",
"                 oHHo   ",
"                oHHHHo  ",
"                 oooo   "
],
[
"   ll             ll    ",
"  lLLll   www   llLLl   ",
"   lLLLllwwwwwllLLLl    ",
"    ooHHHHHHHHHHHoo     ",
"   oHHHHHHHHHHHHHHHo    ",
"  oHHhhhhHHHHhhhhHHHo   ",
"  oHHhwewhHHhwewhHHHo   ",
"  oHHhwewhHHhwewhHHHo   ",
"   oHHhhhHnnHhhhHHHo    ",
"    oHHHHHnnHHHHHHo     ",
" oo oHHHHHHHHHHHHHo oo  ",
"oHHooHHHhhhhhhHHHooHHo  ",
"oHHHHHHhhhhhhhhHHHHHHo  ",
" oHHHHHhHhHhHhHHHHHHo   ",
"  oHHHHhhhhhhhhHHHHo    ",
"   ooHHHhhhhhhHHHoo     ",
"     ooHHHHHHHHoo       ",
"       oooooooo         ",
"       nnn  nnn         "
],
[
"             w          ",
"            wHw         ",
"          wwHHHw        ",
"       oooHHHHHoo       ",
"      oHHHHHHHHHHo      ",
"     oHHHHeHHHHHHHo     ",
"      oHHHeHHHHHHHnn    ",
"       oHHHHHHHHHnnnn   ",
"        oHHHHHHHHHo     ",
" oo    ooHHHHHHHHHoo    ",
"oHHo  oHHHHhhhHHHHHHo   ",
"oHHHooHHHHhhhhhHHHHHHo  ",
"oHHHHHHHHHhhhhhHHHHHHo  ",
" oHHHHHHHHHhhhHHHHHHo   ",
"  oHHHHHHHHHHHHHHHHo    ",
"   oHHHHHHHHHHHHHoo     ",
"    ooHHHHHHHHHoo       ",
"      oooHHoooo         ",
"        nHn             ",
"        nnn             "
],
[
"    ww        ww        ",
"   wHHw      wHHw       ",
"    oHHooooooHHo        ",
"   oHHHHHHHHHHHHo       ",
"  oHHHeHHHHHeHHHHo      ",
"  oHHHeHHHHHeHHHHo      ",
"   oHHHHHHHHHHHHo       ",
"    oHHHHnnHHHHo        ",
"     ooHHHHHHoo         ",
"     oHHhhhhHHo         ",
"    oHHHhhhhHHHo        ",
"   oHHHHhhhhHHHHo       ",
"  oHHHHHhhhhHHHHHo      ",
"   ooHHHhhhhHHHoo       ",
"    oHHHhhhhHHHo        ",
"    oHHHhhhhHHHo   oo   ",
"     oHHHhhhHHHooooHHo  ",
"      oHHHHHHHHHHHHHo   ",
"       ooHHHHHHHHHoo    ",
"         ooooooooo      "
]

]

static var texture_cache: Dictionary = {}

static func draw_creature(canvas: CanvasItem, pos: Vector2, id: int, scale_factor: float, clock: float) -> void:
	var texture := portrait(id)
	var pixel := 3.0*scale_factor
	var bob := roundf(sin(clock*2.8+id)*1.3)*scale_factor if clock != 0 else 0.0
	canvas.draw_texture_rect(texture,Rect2(pos-Vector2(20,18)*pixel+Vector2(0,bob),Vector2(40,36)*pixel),false)

static func portrait(id: int) -> ImageTexture:
	if not texture_cache.has(id): texture_cache[id] = ImageTexture.create_from_image(sprite_image(id))
	return texture_cache[id]

static func sprite_image(id: int) -> Image:
	var species: Dictionary = preload("res://scripts/game_data.gd").SPECIES[id]
	var family := int(species.family)
	var form := int(species.form)
	var image := Image.create(40,36,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var primary: Color = species.color
	var edge := Color("203441")
	var accent := Color("fff1c7")
	# Structural appendages are drawn behind the authored body, never just palette swaps.
	match form:
		1: # Branched dew antlers.
			for x in [12,27]:
				image.fill_rect(Rect2i(x,1,2,11),edge)
				image.fill_rect(Rect2i(x-3,3,8,2),edge)
				image.fill_rect(Rect2i(x-2,2,6,2),accent)
		2: # Long ribbon tail.
			image.fill_rect(Rect2i(29,21,9,4),edge)
			image.fill_rect(Rect2i(35,15,4,10),edge)
			image.fill_rect(Rect2i(30,22,8,2),primary)
			image.fill_rect(Rect2i(36,16,2,7),accent)
		3: # Two sail wings, different family span.
			for x in [1,30]:
				image.fill_rect(Rect2i(x,12,9,13),edge)
				image.fill_rect(Rect2i(x+1,13,7,8),primary.lightened(0.3))
				image.fill_rect(Rect2i(x+2,9,5,4),edge)
		4: # Layered shell mantle.
			image.fill_rect(Rect2i(5,13,29,15),edge)
			image.fill_rect(Rect2i(6,14,27,13),primary.darkened(0.2))
			for y in [16,20,24]: image.fill_rect(Rect2i(6,y,27,1),accent)
		5: # Seven crown spikes.
			for k in range(7):
				image.fill_rect(Rect2i(8+k*4,2+k%2*2,3,9),edge)
				image.fill_rect(Rect2i(9+k*4,3+k%2*2,1,6),accent)
		6: # Stilt legs with webbed feet.
			for x in [12,25]:
				image.fill_rect(Rect2i(x,25,3,9),edge)
				image.fill_rect(Rect2i(x-2,33,7,2),edge)
				image.fill_rect(Rect2i(x+1,27,1,6),primary)
		7: # Wide mushroom crown.
			image.fill_rect(Rect2i(5,7,30,4),edge)
			image.fill_rect(Rect2i(8,4,24,4),edge)
			image.fill_rect(Rect2i(12,2,16,3),edge)
			image.fill_rect(Rect2i(7,8,26,2),primary.lightened(0.2))
		8: # Trailing veil streamers.
			for k in range(5):
				image.fill_rect(Rect2i(3+k*8,18+k%2*3,2,13),edge)
				image.fill_rect(Rect2i(2+k*8,29+k%2*2,5,2),primary.lightened(0.3))
		9: # Tall moon ears and dangling ear chimes.
			for x in [8,29]:
				image.fill_rect(Rect2i(x,1,3,18),edge)
				image.fill_rect(Rect2i(x+1,3,1,12),primary)
				image.fill_rect(Rect2i(x-1,18,5,4),accent)
		10: # Hollow halo, visible above the head and along both sides.
			image.fill_rect(Rect2i(6,1,28,2),accent)
			image.fill_rect(Rect2i(3,4,2,24),accent)
			image.fill_rect(Rect2i(35,4,2,24),accent)
			image.fill_rect(Rect2i(6,29,28,2),accent)
		11: # Crescent-shaped tail.
			image.fill_rect(Rect2i(1,6,3,20),edge)
			image.fill_rect(Rect2i(4,3,6,3),edge)
			image.fill_rect(Rect2i(4,26,10,3),edge)
			image.fill_rect(Rect2i(2,9,1,14),accent)
	var colors := {"o":edge,"H":primary,"h":primary.lightened(0.28),"e":Color("142a37"),"n":Color("9b7659"),"p":Color("d8797d"),"w":accent,"l":Color("387950"),"L":Color("a0cf7b"),"s":Color("937858")}
	for y in range(PATTERNS[family].size()):
		var row: String = PATTERNS[family][y]
		for x in range(row.length()):
			var c := row.substr(x,1)
			if colors.has(c): image.set_pixel(x+8,y+8,colors[c])
	# Foreground badges are species-specific; the eye pixels remain unobstructed.
	if form == 4:
		for k in range(3): image.fill_rect(Rect2i(14+k*4,23,2,3),accent)
	if form == 7:
		for k in range(4): image.fill_rect(Rect2i(9+k*6,6,2,2),accent)
	return image

static func hero_portrait() -> ImageTexture:
	if texture_cache.has("hero"): return texture_cache.hero
	var rows := [
		"       nnnnnnn       ","     nnbbbbbbbnn     ","    nbbbbbbbbbbbn    ","    nbbbbbbbbbbbn    ","   nbbbbbggbbbbbbn   ","    nnnnnnnnnnnnn    ","      ssssssss       ","      sesseess       ","       ssssss        ","     wwwwwwwwww      ","    wWWWWWWWWWWw     ","   wWWWgWWWWWWWWw    ","  wWWWWggWWWWWWWWw   ","  wWWWWgWgWWWWWWWw   ","   wWWWgWWgWWWWWw    ","    wWWgWWWgWWWw     ","    wWWgWWWWgWWw     ","     wwggggggww      ","      nnbbbnn        ","      nnbbbnn        ","     nnn   nnn       "
	]
	var colors := {"n":Color("243a50"),"b":Color("45617b"),"g":Color("d3af72"),"s":Color("edbf9e"),"e":Color("203445"),"w":Color("b0a48c"),"W":Color("eee4c8")}
	var image := Image.create(40,40,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var c: String = rows[y].substr(x,1)
			if colors.has(c): image.set_pixel(x+10,y+8,colors[c])
	texture_cache.hero = ImageTexture.create_from_image(image)
	return texture_cache.hero
