extends Node2D

const Data = preload("res://scripts/game_data.gd")
const Sound = preload("res://scripts/audio.gd")
const SPECIES = Data.SPECIES
const ISLANDS = Data.ISLANDS
const TYPES = ["森", "焰", "潮"]
const SAVE_PATH = "user://tidebound_v2.json"
const ORIGIN = Vector2(40, 146)
const TILE = 40
var party: Array = []
var reserve: Array = []
var known: Array = [0]
var active := 0
var player := Vector2i(2, 5)
var enemy: Dictionary = {}
var mode := "explore"
var seals := 8
var fragments := 0
var wins := 0
var guardian_defeated := false
var guardian_battle := false
var guarding := false
var message := "欢迎来到微光岛。WASD / 方向键移动；草丛中寻找灵兽。"
var journal := "收集 3 枚潮晶，前往东北方的遗迹挑战守卫。"
var zone := 0
var completed: Array = [false, false, false]
var crystals: Array = [0, 0, 0]
var tide := 0
var focus := 3
var salves := 3
var modal: Control
var modal_body: VBoxContainer
var audio: Node
var volume := 0.65
var walk_time := 0.0
var particles: Array = []
var buttons: VBoxContainer
var info: Label
var log_label: Label
var step_timer := 0.0
var rng := RandomNumberGenerator.new()

func creature(id: int, level: int = 1) -> Dictionary:
	var s: Dictionary = SPECIES[id]
	return {"species":id, "level":level, "hp":int(s.max_hp) + (level-1)*6, "max_hp":int(s.max_hp)+(level-1)*6, "xp":0}

func _ready() -> void:
	rng.randomize()
	party = [creature(0)]
	setup_theme()
	audio = Sound.new()
	add_child(audio)
	build_ui()
	load_settings()
	load_game()
	refresh()
	audio.play_track("explore")
	if not OS.get_cmdline_args().has("--skip-title"):
		show_title()

func build_ui() -> void:
	var title := Label.new()
	title.text = "T I D E B O U N D   /   潮汐灵约"
	title.position = Vector2(40, 22)
	title.add_theme_font_size_override("font_size", 29)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "微光群岛     •     原创怪物收集冒险     /     SHORT ADVENTURE 0.2"
	subtitle.position = Vector2(42, 70)
	subtitle.modulate = Color("9aafbb")
	add_child(subtitle)
	info = Label.new()
	info.position = Vector2(800, 145)
	info.size = Vector2(325, 210)
	info.add_theme_font_size_override("font_size", 19)
	add_child(info)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(800, 338)
	scroll.size = Vector2(315, 344)
	add_child(scroll)
	buttons = VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(buttons)
	buttons.add_theme_constant_override("separation", 9)
	log_label = Label.new()
	log_label.position = Vector2(40, 610)
	log_label.size = Vector2(710, 95)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 18)
	add_child(log_label)

func add_button(caption: String, action: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.theme = get_meta("game_theme")
	b.custom_minimum_size = Vector2(295, 35)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(action)
	buttons.add_child(b)

func refresh() -> void:
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	var p: Dictionary = party[active]
	var s: Dictionary = SPECIES[int(p.species)]
	info.text = "%s / %s\n契约符 %d    潮晶 %d / 3\n图鉴 %d / 9    灯塔 %d / 3\n\n%s  Lv.%d  [%s]\n生命 %d / %d    经验 %d / 3" % [ISLANDS[zone].name, "低潮" if tide == 0 else "高潮", seals, fragments, discovered(), completed.count(true), s.name, p.level, TYPES[int(s.type)], p.hp, p.max_hp, p.xp]
	journal = "任务：收集 3 枚潮晶 → 东北灯塔。低潮可通过浅滩。" if not guardian_defeated else "灯塔已点亮。可在右侧选择下一座岛，或继续收集。"
	if completed.count(true) == 3: journal = "三座灯塔已点亮。旅程完成，继续寻找九种灵兽。"
	log_label.text = message + "\n" + journal
	if mode == "battle":
		add_button("攻击 / 稳定输出", turn.bind("attack"))
		add_button("%s / 潮息 %d / 3" % [s.skill, focus], turn.bind("skill"))
		add_button("防御 / 潮息 +1", turn.bind("guard"))
		add_button("药草 / 回复 24 生命（%d）" % salves, turn.bind("heal"))
		add_button("建立契约 / 捕捉", turn.bind("capture"))
		add_button("撤离战斗", turn.bind("flee"))
	else:
		add_button("在营地休息 [E]", rest)
		add_button("营地编队 / 储备灵兽", show_roster)
		add_button("摇响潮铃 [T] / 改变潮相", change_tide)
		add_button("灵兽图鉴 / 九种灵兽", show_dex)
		add_button("旅程菜单 [Esc]", show_pause)
		if guardian_defeated and zone < 2:
			add_button("启航 → " + str(ISLANDS[zone+1].name), travel.bind(zone+1))
		for island in range(zone):
			add_button("返回 " + str(ISLANDS[island].name), travel.bind(island))
		if zone < 2 and completed[zone] and completed[zone+1]:
			add_button("前往 " + str(ISLANDS[zone+1].name), travel.bind(zone+1))
	for i in range(party.size()):
		if i != active:
			add_button("换上 %s  %d/%d" % [SPECIES[int(party[i].species)].name, party[i].hp, party[i].max_hp], switch_to.bind(i))
	queue_redraw()

func discovered() -> int:
	return known.size()

func _process(delta: float) -> void:
	walk_time += delta
	queue_redraw()
	step_timer -= delta
	if modal != null or mode != "explore": return
	if Input.is_physical_key_pressed(KEY_E): rest()
	if step_timer > 0: return
	var d := Vector2i.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"): d.x = -1
	elif Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): d.x = 1
	elif Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"): d.y = -1
	elif Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"): d.y = 1
	if d == Vector2i.ZERO: return
	step_timer = 0.16
	move_player(d)

func is_grass(p: Vector2i) -> bool:
	if p.y == 5 or (p.x == 15 and p.y <= 5): return false
	return (p.x >= 5 and p.x <= 10 and p.y >= 3 and p.y <= 8) or (p.x >= 13 and p.y >= 6)

func move_player(d: Vector2i) -> void:
	var target := player + d
	if target.x < 1 or target.x > 16 or target.y < 1 or target.y > 9: return
	if target.x == 11 and tide == 1:
		message = "海水淹没了浅滩。按 T 摇铃退潮，旧路就会显露。"
		refresh()
		return
	if target in obstacle_tiles(): return
	player = target
	if player == Vector2i(15, 2):
		if guardian_defeated: message = "灯塔已恢复光芒。可继续探索，或从右侧菜单启航。"
		elif fragments >= 3: start_battle(int(ISLANDS[zone].boss), true)
		else: message = "遗迹需要 3 枚潮晶。赢得野外战斗或建立契约可以获得潮晶。"
	elif is_grass(player) and rng.randf() < 0.23:
		start_battle(zone*3 + rng.randi_range(0, 1) + tide)
	elif player.distance_to(Vector2i(2, 5)) <= 1:
		message = "营地：按 E 恢复全队生命，并补给至 8 张契约符。"
	refresh()

func start_battle(id: int, guardian: bool = false) -> void:
	mode = "battle"
	guardian_battle = guardian
	enemy = creature(id, int(ISLANDS[zone].level) if guardian else rng.randi_range(1+zone*2, 2+zone*2))
	focus = 3
	salves = 3
	audio.play_track("battle")
	audio.sfx("hit")
	message = ("遗迹守卫出现！" if guardian else "草丛中出现了 " + str(SPECIES[id].name) + "！")
	refresh()

func effectiveness(attacker: int, defender: int) -> float:
	if (attacker + 2) % 3 == defender: return 1.5
	if (attacker + 1) % 3 == defender: return 0.7
	return 1.0

func turn(action: String) -> void:
	if mode != "battle": return
	var p: Dictionary = party[active]
	var s: Dictionary = SPECIES[int(p.species)]
	var e: Dictionary = SPECIES[int(enemy.species)]
	guarding = false
	match action:
		"flee":
			mode = "explore"
			audio.play_track("explore")
			message = "你安全撤回小径。"
			refresh()
			return
		"capture":
			if guardian_battle:
				message = "守卫维系着遗迹，无法建立契约。"
				refresh()
				return
			if seals <= 0 or reserve.size() >= 50:
				message = "契约符不足或储备已满（50 只），请回营地整理。"
				refresh()
				return
			seals -= 1
			var chance := 0.2 + 0.7 * (1.0 - float(enemy.hp) / float(enemy.max_hp))
			if rng.randf() < chance:
				if not known.has(int(enemy.species)): known.append(int(enemy.species))
				if party.size() < 6: party.append(enemy.duplicate(true))
				else: reserve.append(enemy.duplicate(true))
				finish_battle("契约成立！" + str(e.name) + " 加入了队伍。")
				return
			message = "共鸣尚不稳定。降低对方生命会提高成功率。"
		"guard":
			focus = mini(3, focus+1)
			guarding = true
			message = "你凝聚潮息，抵御下一次攻击。"
		"heal":
			if salves <= 0:
				message = "本场药草已经用尽。"
				refresh()
				return
			salves -= 1
			p.hp = mini(int(p.max_hp), int(p.hp)+24)
			message = "药草恢复了 24 点生命。"
		_:
			if action == "skill" and focus < 2:
				message = "潮息不足。普通攻击或防御可以恢复潮息。"
				refresh()
				return
			focus = focus-2 if action == "skill" else mini(3, focus+1)
			var mult := effectiveness(int(s.type), int(e.type)) if action == "skill" else 1.0
			if action == "skill":
				mult *= 1.2
				if int(s.type) == (2 if tide == 1 else 1): mult *= 1.2
			var damage := maxi(1, int((int(s.power) + int(p.level)*2) * mult) + rng.randi_range(-2, 2))
			audio.sfx("hit")
			enemy.hp = maxi(0, int(enemy.hp) - damage)
			message = "%s造成 %d 点伤害。%s" % ["共鸣技" if action == "skill" else "攻击", damage, "属性优势！" if mult > 1 else ""]
			if int(enemy.hp) <= 0:
				finish_battle("战斗胜利！")
				return
	enemy_turn()

func enemy_turn() -> void:
	var p: Dictionary = party[active]
	var damage := int(SPECIES[int(enemy.species)].power) + int(enemy.level)
	if guarding: damage = maxi(1, damage / 3)
	p.hp = maxi(0, int(p.hp) - damage)
	message += " 对方反击 %d 点。" % damage
	if int(p.hp) <= 0:
		for i in range(party.size()):
			if int(party[i].hp) > 0:
				active = i
				message += " 同伴接替了战斗。"
				refresh()
				return
		mode = "explore"
		player = Vector2i(2, 5)
		heal_party()
		audio.play_track("explore")
		message = "队伍失去战斗能力。营地救援后已恢复，旅程可以继续。"
	refresh()

func finish_battle(text: String) -> void:
	mode = "explore"
	audio.play_track("explore")
	audio.sfx("win")
	wins += 1
	fragments = mini(3, fragments + 1)
	crystals[zone] = fragments
	var p: Dictionary = party[active]
	p.xp = int(p.xp) + 1
	if int(p.xp) >= 3:
		if int(p.level) >= 99: p.xp = 0
		else: p.level = int(p.level) + 1
		p.xp = 0
		p.max_hp = int(p.max_hp) + 6
		p.hp = p.max_hp
		text += " 同伴升级，生命恢复！"
	if guardian_battle:
		guardian_defeated = true
		completed[zone] = true
		text += " 你点亮了" + str(ISLANDS[zone].name) + "！"
		heal_party()
	message = text + " 获得 1 枚潮晶。"
	save_game(false)
	refresh()
	if guardian_battle: show_story(str(ISLANDS[zone].ending))

func switch_to(index: int) -> void:
	if int(party[index].hp) <= 0: return
	active = index
	message = "出战灵兽已切换。"
	if mode == "battle": enemy_turn()
	else: refresh()

func heal_party() -> void:
	for p in party + reserve: p.hp = p.max_hp
	seals = maxi(seals, 8)

func rest() -> void:
	if mode != "explore": return
	if player.distance_to(Vector2i(2, 5)) > 1:
		message = "请回到西侧营地（帐篷）休息。"
	else:
		heal_party()
		message = "全队恢复了精神，契约符补给完毕。"
		save_game(false)
	refresh()

func save_game(notify: bool = true) -> void:
	var file := FileAccess.open(SAVE_PATH+".tmp", FileAccess.WRITE)
	if file == null:
		message = "存档失败：无法写入用户目录。"
		refresh()
		return
	file.store_string(JSON.stringify({"version":2,"zone":zone,"completed":completed,"crystals":crystals,"tide":tide,"party":party,"reserve":reserve,"known":known,"active":active,"seals":seals,"fragments":fragments,"wins":wins,"guardian":guardian_defeated,"x":player.x,"y":player.y}))
	file.close()
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(SAVE_PATH,SAVE_PATH+".bak")
	if DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH) != OK:
		message = "存档替换失败，旧存档保持不变。"
		refresh()
		return
	if notify:
		message = "旅程已保存。下次启动会自动继续。"
		refresh()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var raw := FileAccess.get_file_as_string(SAVE_PATH)
	if raw.length() > 262144: return
	var parser := JSON.new()
	if parser.parse(raw) != OK: return
	var data = parser.data
	if not data is Dictionary or data.get("version") != 2: return
	var loaded = data.get("party", [])
	if not loaded is Array or loaded.is_empty() or loaded.size() > 6: return
	for p in loaded:
		if not valid_creature(p): return
	var saved_completed = data.get("completed",[])
	var saved_crystals = data.get("crystals",[])
	if not saved_completed is Array or saved_completed.size() != 3 or not saved_crystals is Array or saved_crystals.size() != 3: return
	for v in saved_completed:
		if not v is bool: return
	for v in saved_crystals:
		if not (v is float or v is int): return
	completed = saved_completed
	crystals = saved_crystals
	zone = clampi(int(data.get("zone",0)),0,2)
	tide = clampi(int(data.get("tide",0)),0,1)
	var saved_reserve = data.get("reserve",[])
	if not saved_reserve is Array or saved_reserve.size() > 50: return
	for p in saved_reserve:
		if not valid_creature(p): return
	var saved_known = data.get("known",[0])
	if not saved_known is Array or saved_known.size() > 9: return
	for id in saved_known:
		if not (id is int or id is float) or int(id) < 0 or int(id) >= 9: return
	known = []
	for id in saved_known:
		if not known.has(int(id)): known.append(int(id))
	reserve = saved_reserve
	party = loaded
	active = clampi(int(data.get("active",0)), 0, party.size()-1)
	seals = maxi(0,int(data.get("seals",8)))
	fragments = clampi(int(data.get("fragments",0)),0,3)
	wins = maxi(0,int(data.get("wins",0)))
	guardian_defeated = bool(completed[zone])
	player = Vector2i(clampi(int(data.get("x",2)),1,16),clampi(int(data.get("y",5)),1,9))
	if guardian_defeated: journal = "试玩完成 / 遗迹重燃。继续探索，收集所有灵兽。"
	message = "已恢复上次的旅程。"

func _draw() -> void:
	draw_rect(Rect2(0,0,1152,720),Color("101e2b"))
	draw_rect(Rect2(782,126,350,570),Color("192d3b"))
	draw_rect(Rect2(38,144,724,444),Color("54818a"))
	if mode == "battle":
		draw_battle()
		return
	for y in range(11):
		for x in range(18):
			var pos := ORIGIN + Vector2(x,y)*TILE
			var border := x == 0 or y == 0 or x == 17 or y == 10
			draw_rect(Rect2(pos,Vector2(TILE,TILE)),ISLANDS[zone].water if border or (x == 11 and tide == 1) else ISLANDS[zone].grass if is_grass(Vector2i(x,y)) else Color("cebfa0") if x == 11 else ISLANDS[zone].ground)
			if border or (x == 11 and tide == 1):
				var drift := sin(walk_time*1.7+x+y)*3
				draw_line(pos+Vector2(8+drift,22),pos+Vector2(28+drift,22),Color("468298"),2)
			elif is_grass(Vector2i(x,y)):
				for k in range(3):
					var tip := pos + Vector2(8+k*11,10+(x+y+k)%8)
					draw_line(tip+Vector2(0,16),tip,Color("7cb779"),3)
	# Worn paths, shore stones, and island-specific foliage.
	for x in range(1,17):
		if x == 11 and tide == 1: continue
		draw_rect(Rect2(ORIGIN+Vector2(x,5)*TILE+Vector2(0,9),Vector2(40,22)),Color("c5b797"))
	for y in range(2,6): draw_rect(Rect2(ORIGIN+Vector2(15,y)*TILE+Vector2(9,0),Vector2(22,40)),Color("c5b797"))
	for tile in obstacle_tiles(): draw_tree(ORIGIN+Vector2(tile)*TILE+Vector2(20,23),zone)
	for y in range(1,10):
		for x in range(1,17):
			if (x*7+y*13+zone)%17 == 0 and not is_grass(Vector2i(x,y)) and x != 11:
				var flower := ORIGIN+Vector2(x,y)*TILE+Vector2(7,12)
				draw_rect(Rect2(flower,Vector2(4,7)),Color("507c65"))
				draw_rect(Rect2(flower+Vector2(-2,-2),Vector2(8,5)),Color("e8d7a1") if zone != 1 else Color("c7b3d8"))
	var dock := ORIGIN+Vector2(16,8)*TILE
	for plank in range(4): draw_rect(Rect2(dock+Vector2(-6,plank*7),Vector2(46,5)),Color("93785e"))
	draw_rect(Rect2(dock+Vector2(30,-5),Vector2(5,40)),Color("e2cba1"))
	# Camp and ancient beacon.
	var camp := ORIGIN + Vector2(2,5)*TILE
	draw_colored_polygon(PackedVector2Array([camp+Vector2(0,35),camp+Vector2(20,2),camp+Vector2(40,35)]),Color("f1bd77"))
	draw_rect(Rect2(camp+Vector2(17,22),Vector2(8,13)),Color("54464c"))
	draw_rect(Rect2(camp+Vector2(-12,35),Vector2(8,4)),Color("5e524c"))
	draw_rect(Rect2(camp+Vector2(-10,24+sin(walk_time*6)*2),Vector2(4,10)),Color("f7bd78"))
	var ruin := ORIGIN + Vector2(15,2)*TILE
	draw_rect(Rect2(ruin+Vector2(-5,33),Vector2(50,7)),Color("6f8b91"))
	draw_rect(Rect2(ruin+Vector2(3,-7),Vector2(35,9)),Color("d3d7bd"))
	draw_rect(Rect2(ruin+Vector2(8,0),Vector2(25,38)),Color("adc2c3"))
	draw_rect(Rect2(ruin+Vector2(8,20),Vector2(25,5)),Color("748f95"))
	draw_rect(Rect2(ruin+Vector2(14,6),Vector2(13,16)),Color("96e4c0") if guardian_defeated else Color("d9b575"))
	var map_font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	draw_string(map_font,ORIGIN+Vector2(54,193),"营地",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
	draw_string(map_font,ORIGIN+Vector2(580,64),"灯塔",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
	var hero := ORIGIN + Vector2(player)*TILE
	draw_rect(Rect2(hero+Vector2(10,30),Vector2(24,6)),Color("50665a"))
	draw_rect(Rect2(hero+Vector2(12,13),Vector2(18,20)),Color("eff0d8"))
	draw_rect(Rect2(hero+Vector2(13,5),Vector2(16,13)),Color("edbe9b"))
	draw_rect(Rect2(hero+Vector2(9,2),Vector2(24,7)),Color("415875"))
	draw_rect(Rect2(hero+Vector2(27,18),Vector2(6,13)),Color("d78668"))

func draw_beast(pos: Vector2, id: int, scale_factor: float) -> void:
	var c: Color = SPECIES[id].color
	var shape := id % 3
	draw_ellipse_shadow(pos + Vector2(0,43)*scale_factor,Vector2(50,10)*scale_factor)
	var blocks := [Rect2(-27,-16,54,48),Rect2(-19,-32,38,22),Rect2(-32,22,18,17),Rect2(14,22,18,17)]
	for r in blocks: draw_rect(Rect2(pos+r.position*scale_factor,r.size*scale_factor),c)
	if shape == 0:
		draw_rect(Rect2(pos+Vector2(-8,-52)*scale_factor,Vector2(13,26)*scale_factor),Color("58a86e"))
		draw_rect(Rect2(pos+Vector2(3,-46)*scale_factor,Vector2(20,10)*scale_factor),Color("b9e492"))
	elif shape == 1:
		for x in [-24,12]: draw_rect(Rect2(pos+Vector2(x,-47)*scale_factor,Vector2(13,24)*scale_factor),c)
		draw_rect(Rect2(pos+Vector2(25,3)*scale_factor,Vector2(24,14)*scale_factor),Color("f9d58b"))
	else:
		for x in [-42,27]: draw_rect(Rect2(pos+Vector2(x,0)*scale_factor,Vector2(15,24)*scale_factor),Color("a2e6e4"))
	if id >= 3:
		for k in range(3):
			draw_rect(Rect2(pos+Vector2(-16+k*12,-27)*scale_factor,Vector2(6,8)*scale_factor),Color("eff0c3"))
	if id >= 6:
		draw_rect(Rect2(pos+Vector2(-8,-45)*scale_factor,Vector2(16,9)*scale_factor),Color("f4db98"))
	for x in [-14,9]: draw_rect(Rect2(pos+Vector2(x,-10)*scale_factor,Vector2(6,9)*scale_factor),Color("1c3445"))
	draw_rect(Rect2(pos+Vector2(-6,10)*scale_factor,Vector2(12,4)*scale_factor),Color("45616b"))

func draw_ellipse_shadow(pos: Vector2, size_value: Vector2) -> void:
	draw_set_transform(pos,0,Vector2(1,size_value.y/size_value.x))
	draw_circle(Vector2.ZERO,size_value.x,Color("243b48"))
	draw_set_transform(Vector2.ZERO)

func draw_battle() -> void:
	draw_rect(Rect2(40,146,720,440),Color("234453"))
	for i in range(9): draw_rect(Rect2(40,146+i*49,720,1),Color("2b4c59"))
	draw_beast(Vector2(220,435),int(party[active].species),2.1)
	draw_beast(Vector2(565,310),int(enemy.species),1.8)
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	draw_string(font,Vector2(432,180),str(SPECIES[int(enemy.species)].name)+"  Lv."+str(enemy.level),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f3e5c1"))
	draw_rect(Rect2(432,196,260,12),Color("172b38"))
	draw_rect(Rect2(432,196,260*float(enemy.hp)/float(enemy.max_hp),12),Color("86d3a2"))
	draw_string(font,Vector2(432,235),"HP %d / %d" % [enemy.hp,enemy.max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
	draw_string(font,Vector2(70,560),"森 → 潮 → 焰 → 森   /   %s增强%s属性技" % ["高潮" if tide else "低潮", "潮" if tide else "焰"],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b0c6c7"))

func setup_theme() -> void:
	var theme := Theme.new()
	theme.default_font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	theme.default_font_size = 18
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("294655") if state == "normal" else Color("426a70") if state == "hover" else Color("355a65")
		style.border_color = Color("e8cd95") if state == "focus" else Color("53787b")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 12
		style.content_margin_right = 12
		theme.set_stylebox("%s" % state,"Button",style)
	get_viewport().gui_embed_subwindows = false
	# A root Theme is applied through the viewport's theme fallback project setting.
	ThemeDB.fallback_font = theme.default_font
	ThemeDB.fallback_font_size = 18
	set_meta("game_theme",theme)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			if modal != null: close_modal()
			else: show_pause()
		elif event.physical_keycode == KEY_T and modal == null and mode == "explore": change_tide()

func close_modal() -> void:
	if modal != null:
		remove_child(modal)
		modal.queue_free()
		modal = null

func open_modal(title: String, text: String) -> void:
	close_modal()
	modal = Control.new()
	modal.theme = get_meta("game_theme")
	modal.size = Vector2(1152,720)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.06,0.10,0.94)
	shade.size = Vector2(1152,720)
	modal.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(190,75)
	panel.size = Vector2(772,570)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("192f3d")
	box.border_color = Color("b6c7ab")
	box.set_border_width_all(2)
	box.content_margin_left = 30
	box.content_margin_top = 22
	box.content_margin_right = 30
	box.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel",box)
	modal.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(704,514)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	modal_body = VBoxContainer.new()
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",13)
	scroll.add_child(modal_body)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",30)
	heading.modulate = Color("f2d7a0")
	modal_body.add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 660
	body.add_theme_font_size_override("font_size",18)
	modal_body.add_child(body)
	add_child(modal)

func modal_button(text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.pressed.connect(callback)
	modal_body.add_child(b)
	if modal_body.get_child_count() == 3: b.grab_focus()

func show_title() -> void:
	open_modal("潮 汐 灵 约  /  T I D E B O U N D", "海水会记住每一次约定。\n探索三座岛屿，结识九种灵兽，点亮群岛最后的灯塔。\n\n原创单机短篇 · v0.2.0\n键鼠操作：WASD / 方向键移动，鼠标选择，T 改变潮相。")
	if FileAccess.file_exists(SAVE_PATH): modal_button("继续旅程",close_modal)
	modal_button("开始新的旅程",confirm_new_game)
	modal_button("设置与操作说明",show_settings)
	modal_button("制作与版权",show_credits)
	modal_button("退出游戏",quit_game)

func confirm_new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		open_modal("新的潮汐", "开始新旅程会覆盖当前存档。旧存档会保留一份 .bak 备份。")
		modal_button("确认开始",new_game)
		modal_button("返回",show_title)
	else: new_game()

func new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(SAVE_PATH,SAVE_PATH+".bak")
	party = [creature(0)]
	reserve = []
	known = [0]
	active = 0
	player = Vector2i(2,5)
	zone = 0
	completed = [false,false,false]
	crystals = [0,0,0]
	fragments = 0
	guardian_defeated = false
	guardian_battle = false
	mode = "explore"
	tide = 0
	wins = 0
	seals = 8
	message = "第一位同伴苔芽兽，已经在营地等你。"
	save_game(false)
	refresh()
	show_story(str(ISLANDS[0].intro)+"\n\n营地可免费恢复。草丛会遇到灵兽；每次战斗胜利或捕捉可获得一枚潮晶。三枚潮晶唤醒东北灯塔的守卫。")

func show_story(text: String) -> void:
	open_modal(str(ISLANDS[zone].subtitle),text)
	modal_button("让旅程继续",close_modal)

func show_pause() -> void:
	open_modal("守灯人的行囊", "进度：%d / 3 座灯塔  ·  图鉴 %d / 9\n%s" % [completed.count(true),discovered(),ISLANDS[zone].subtitle])
	modal_button("继续旅程",close_modal)
	if mode == "explore": modal_button("保存旅程",func(): save_game(); close_modal())
	modal_button("图鉴",show_dex)
	modal_button("设置与操作说明",show_settings)
	modal_button("返回标题",show_title)
	modal_button("保存并退出" if mode == "explore" else "退出（回到最近自动存档）",quit_game)

func show_dex() -> void:
	var text := "灵兽生态手记  ·  %d / 9 已建立契约\n\n" % discovered()
	for id in range(SPECIES.size()):
		var owned := known.has(id)
		text += "%02d  %s  [%s]  ·  %s\n%s\n\n" % [id+1,SPECIES[id].name,TYPES[int(SPECIES[id].type)],"已结识" if owned else "未建立契约",SPECIES[id].lore if owned else "栖息地："+str(ISLANDS[int(id/3)].name)+"。低潮与高潮出现的灵兽不同。"]
	open_modal("群岛图鉴",text)
	modal_button("返回旅程",close_modal)

func show_settings() -> void:
	open_modal("设置与操作", "WASD / 方向键：移动    T：改变潮相    E：营地休息\nEsc：菜单 / 返回    鼠标：选择    Tab：切换按钮焦点\n\n低潮：浅滩可通行，焰属性技能增强。\n高潮：浅滩淹没，潮属性技能增强，出现不同灵兽。\n普通攻击与防御恢复潮息；共鸣技消耗 2 点潮息。\n每场战斗有 3 份药草，切换同伴会消耗回合。\n\n音量")
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = volume
	slider.custom_minimum_size.y = 30
	slider.value_changed.connect(func(value: float): volume=value; audio.set_volume(value); save_settings())
	modal_body.add_child(slider)
	modal_button("切换全屏 / 窗口",toggle_fullscreen)
	modal_button("返回旅程",close_modal)

func toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio","volume",volume)
	cfg.set_value("display","fullscreen",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	cfg.save("user://settings.cfg")

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		volume = clampf(float(cfg.get_value("audio","volume",0.65)),0,1)
		if bool(cfg.get_value("display","fullscreen",false)) and DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	audio.set_volume(volume)

func show_credits() -> void:
	open_modal("制作与版权", "潮汐灵约 / Tidebound\n原创游戏代码、程序绘制像素图形与合成音乐。\n使用 Godot Engine 4.6.3（MIT）。\n字体：Noto Sans CJK（SIL Open Font License 1.1）。\n许可全文随源码与发行包提供。\n\n本游戏为独立原创项目，与其他怪物收集作品无隶属关系。\n当前版本不联网、不含内购、不采集遥测。")
	modal_button("返回",show_title)

func change_tide() -> void:
	if mode != "explore": return
	tide = 1-tide
	if tide == 1 and player.x == 11: player.x = 10
	message = "潮铃响起，" + ("海水退去，旧石桥与浅滩重见天日。" if tide == 0 else "海水涨起，远方的灵兽循着歌声归来。")
	audio.sfx("bell")
	refresh()

func travel(destination: int) -> void:
	if mode != "explore" or destination < 0 or destination > 2: return
	if destination > 0 and not completed[destination-1]: return
	crystals[zone] = fragments
	zone = destination
	fragments = int(crystals[zone])
	guardian_defeated = bool(completed[zone])
	player = Vector2i(2,5)
	tide = 0
	heal_party()
	message = "抵达" + str(ISLANDS[zone].name) + "，营地已准备好。"
	save_game(false)
	refresh()
	show_story(str(ISLANDS[zone].intro))

func quit_game() -> void:
	if mode == "explore": save_game(false)
	get_tree().quit()

func valid_creature(p: Variant) -> bool:
	if not p is Dictionary: return false
	for key in ["species","level","hp","max_hp","xp"]:
		if not p.has(key) or not (p[key] is int or p[key] is float): return false
	return int(p.species) >= 0 and int(p.species) < 9 and int(p.level) >= 1 and int(p.level) <= 99 and int(p.max_hp) > 0 and int(p.max_hp) <= 1000 and int(p.hp) >= 0 and int(p.hp) <= int(p.max_hp) and int(p.xp) >= 0 and int(p.xp) < 3

func show_roster() -> void:
	if mode != "explore" or player.distance_to(Vector2i(2,5)) > 1:
		message = "请回营地编队。队伍最多六只，新结识的灵兽会进入营地储备。"
		refresh()
		return
	open_modal("营地 · 同伴编队", "当前队伍 %d / 6，储备 %d / 50。\n点击储备灵兽与当前出战同伴交换；未满六只时会直接加入队伍。" % [party.size(),reserve.size()])
	for i in range(reserve.size()):
		var p: Dictionary = reserve[i]
		modal_button("%s  Lv.%d  [%s]" % [SPECIES[int(p.species)].name,p.level,TYPES[int(SPECIES[int(p.species)].type)]],withdraw.bind(i))
	if reserve.is_empty():
		var text := Label.new()
		text.text = "暂无储备灵兽。队伍满员后，新的同伴会在这里等你。"
		modal_body.add_child(text)
	modal_button("返回旅程",close_modal)

func withdraw(index: int) -> void:
	if index < 0 or index >= reserve.size(): return
	if party.size() < 6: party.append(reserve.pop_at(index))
	else:
		var old: Dictionary = party[active]
		party[active] = reserve[index]
		reserve[index] = old
	save_game(false)
	refresh()
	show_roster()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			if modal != null: close_modal()
			else: show_pause()
		elif modal == null and mode == "explore":
			if event.button_index == JOY_BUTTON_X: change_tide()
			elif event.button_index == JOY_BUTTON_Y: rest()

func obstacle_tiles() -> Array:
	return [Vector2i(3,2),Vector2i(4,2),Vector2i(3,3),Vector2i(8,1),Vector2i(9,1),Vector2i(13,3),Vector2i(14,3),Vector2i(16,5),Vector2i(4,8),Vector2i(3,8),Vector2i(2,9)]

func draw_tree(pos: Vector2, variant: int) -> void:
	draw_rect(Rect2(pos+Vector2(-18,13),Vector2(36,7)),Color("4d6c5f"))
	draw_rect(Rect2(pos+Vector2(-4,-7),Vector2(8,23)),Color("7b6550"))
	var leaf := Color("497b62") if variant == 0 else Color("687a98") if variant == 1 else Color("798d6d")
	for r in [Rect2(-20,-22,40,26),Rect2(-14,-32,28,18),Rect2(-9,-39,18,12)]: draw_rect(Rect2(pos+r.position,r.size),leaf)
	draw_rect(Rect2(pos+Vector2(-13,-28),Vector2(8,13)),leaf.lightened(0.17))
	draw_rect(Rect2(pos+Vector2(8,-18),Vector2(9,15)),leaf.darkened(0.15))
	if variant == 1: draw_rect(Rect2(pos+Vector2(-2,-29),Vector2(4,7)),Color("e9d99b"))
