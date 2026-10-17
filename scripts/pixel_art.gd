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

static func draw_creature(canvas: CanvasItem, pos: Vector2, id: int, scale_factor: float, clock: float) -> void:
	var rows: Array = PATTERNS[id]
	var primary: Color = preload("res://scripts/game_data.gd").SPECIES[id].color
	var colors := {"o":Color("203441"),"H":primary,"h":primary.lightened(0.28),"e":Color("142a37"),"n":Color("9b7659"),"p":Color("d8797d"),"w":Color("fff1c7"),"l":Color("387950"),"L":Color("a0cf7b"),"s":Color("937858")}
	var pixel := 3.0*scale_factor
	var bob := roundf(sin(clock*2.8+id)*1.3)*scale_factor
	var origin := pos-Vector2(12*pixel,12*pixel)+Vector2(0,bob)
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var c := row.substr(x,1)
			if colors.has(c): canvas.draw_rect(Rect2(origin+Vector2(x,y)*pixel,Vector2(pixel,pixel)),colors[c])

static func portrait(id: int) -> ImageTexture:
	var image := Image.create(28,26,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var primary: Color = preload("res://scripts/game_data.gd").SPECIES[id].color
	var colors := {"o":Color("203441"),"H":primary,"h":primary.lightened(0.28),"e":Color("142a37"),"n":Color("9b7659"),"p":Color("d8797d"),"w":Color("fff1c7"),"l":Color("387950"),"L":Color("a0cf7b"),"s":Color("937858")}
	for y in range(PATTERNS[id].size()):
		var row: String = PATTERNS[id][y]
		for x in range(row.length()):
			var c := row.substr(x,1)
			if colors.has(c): image.set_pixel(x+2,y+2,colors[c])
	return ImageTexture.create_from_image(image)
