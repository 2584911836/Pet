extends Node2D

const Data = preload("res://scripts/game_data.gd")
const Story = preload("res://scripts/story.gd")
var story_flags: Dictionary = {}
var tracked_goal := "main"
var guide_path: Array = []
var quest_label: Label
var subtitle_label: Label
var action_scroll: ScrollContainer
var battle_layout := false
var actions_key := ""
const WorldArt = preload("res://scripts/world_art.gd")
const Sound = preload("res://scripts/audio.gd")
const SPECIES = Data.SPECIES
const ISLANDS = Data.ISLANDS
const PET_COUNT = 108
const AREAS = [["青芽镇","曙光林","溪谷驿道"],["赤岩镇","琥珀矿径","货运栈道"],["联赛中心","星冠林","研究站外围"]]
const Elements = preload("res://scripts/elements.gd")
const Moves = preload("res://scripts/battle_moves.gd")
const TYPES = Elements.NAMES
var enemy_focus := 3
const SAVE_PATH = "user://tidebound_v2.json"
const ORIGIN = Vector2(40, 146)
const TILE = 40
var party: Array = []
var reserve: Array = []
var known: Array = [0]
var active := 0
var player := Vector2i(2, 6)
var visual_player := Vector2(2,6)
var companion_target := Vector2(2,7)
var companion_visual := Vector2(2,7)
var steps_walked := 0
var seconds_played := 0.0
var enemy: Dictionary = {}
var mode := "explore"
var seals := 8
var fragments := 0
var wins := 0
var guardian_defeated := false
var collection_rewarded := false
var keeper_rewards: Array = [false,false,false]
var guardian_battle := false
var guarding := false
var message := "欢迎来到青芽镇。WASD / 方向键移动；草丛中寻找灵兽。"
var journal := "收集 3 枚资格积分，前往东北赛场挑战导师。"
var zone := 0
var area := 0
var dex_page := 0
var dex_filter := 0
var reserve_page := 0
var completed: Array = [false, false, false]
var crystals: Array = [0, 0, 0]
var special_battle_kind := ""
var opponent_roster: Array = []
var opponent_slot := 0
var focus := 3
const Signature = preload("res://scripts/signature_skills.gd")
var battle_status: Label
var combat_states: Dictionary = {}
var enemy_status: Dictionary = {}
var enemy_round := 0
var battle_id := 0
var relics: Array = [false,false,false,false,false,false]
var salves := 3
var modal: Control
var modal_body: VBoxContainer
var audio: Node
var volume := 0.65
var reduce_motion := false
var walk_time := 0.0
var busy := false
var quitting := false
var animations_enabled := true
var impact_left := 0.0
var impact_enemy := true
var floating_text := ""
var buttons: Container
var info: Label
var log_label: Label
var step_timer := 0.0
var rng := RandomNumberGenerator.new()

func creature(id: int, level: int = 1) -> Dictionary:
	var s: Dictionary = SPECIES[id]
	return {"species":id, "level":level, "hp":int(s.max_hp) + (level-1)*6, "max_hp":int(s.max_hp)+(level-1)*6, "xp":0}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(quit_game)
	rng.randomize()
	party = [creature(0)]
	setup_theme()
	audio = Sound.new()
	add_child(audio)
	build_ui()
	load_settings()
	load_game()
	reset_visual_positions()
	refresh()
	audio.play_track("island_"+str(zone))
	if not OS.get_cmdline_args().has("--skip-title"):
		show_title()

func build_ui() -> void:
	var title := Label.new()
	title.text = "S T A R W I L D   /   星野伙伴"
	title.position = Vector2(40, 22)
	title.add_theme_font_size_override("font_size", 29)
	add_child(title)
	subtitle_label = Label.new()
	subtitle_label.text = "微光地区     •     原创怪物收集冒险     /     SHORT ADVENTURE 0.9"
	subtitle_label.position = Vector2(42, 70)
	subtitle_label.modulate = Color("9aafbb")
	add_child(subtitle_label)
	battle_status = Label.new()
	battle_status.position = Vector2(45,100)
	battle_status.size = Vector2(710,64)
	battle_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_status.add_theme_font_size_override("font_size",14)
	battle_status.modulate = Color("b8dbd3")
	add_child(battle_status)
	quest_label = Label.new()
	quest_label.position = Vector2(42,101)
	quest_label.size = Vector2(710,36)
	quest_label.add_theme_font_size_override("font_size",15)
	quest_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	quest_label.modulate = Color("f3d89d")
	add_child(quest_label)
	info = Label.new()
	info.position = Vector2(800, 145)
	info.size = Vector2(325, 210)
	info.add_theme_font_size_override("font_size", 19)
	add_child(info)
	action_scroll = ScrollContainer.new()
	action_scroll.position = Vector2(800, 338)
	action_scroll.size = Vector2(315, 344)
	add_child(action_scroll)
	buttons = VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(buttons)
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
	b.tooltip_text = caption
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.theme = get_meta("game_theme")
	b.custom_minimum_size = Vector2(154,62) if mode == "battle" else Vector2(295,35)
	b.add_theme_font_size_override("font_size",14 if mode == "battle" else 17)
	b.disabled = busy
	b.pressed.connect(action)
	buttons.add_child(b)

func update_status() -> void:
	var p: Dictionary = party[active]
	var s: Dictionary = SPECIES[int(p.species)]
	info.text = "%s / %s\n捕捉胶囊 %d    资格积分 %d / 3\n图鉴 %d / 108    地区徽章 %d / 3\n\n%s  Lv.%d  [%s]\n生命 %d / %d    经验 %d / 3" % [AREAS[zone][area], "训练师旅程", seals, fragments, discovered(), completed.count(true), s.name, p.level, Elements.names(s.elements), p.hp, p.max_hp, p.xp]
	var objective: Dictionary = Story.objective(self)
	journal = str(objective.step)+" · "+str(objective.progress)
	quest_label.visible = mode == "explore"
	quest_label.text = "[J 任务] "+journal
	subtitle_label.text = str(Story.CHAPTERS[zone].title)+"  /  "+str(AREAS[zone][area])+"  ·  M 地图  J 日志  R 交谈"
	log_label.text = message if mode == "battle" else message+"\n"+journal
	if mode == "explore":
		info.add_theme_font_size_override("font_size",19)
		observe_region()
		update_guide()
	else:
		info.add_theme_font_size_override("font_size",17)
		info.text = "%s · 第 %d 回合\n%s  Lv.%d\n[%s]   生命 %d / %d\n能量 %d / 3    药草 %d" % ["父母救援" if special_battle_kind == "rescue" else "冠军赛" if special_battle_kind == "championship" else "地区资格赛" if guardian_battle else "野外遭遇",enemy_round+1,s.name,p.level,Elements.names(s.elements),p.hp,p.max_hp,focus,salves]
	if mode == "battle" and not opponent_roster.is_empty(): info.text += "\n对方阵容 %d / %d" % [opponent_slot+1,opponent_roster.size()]
	battle_status.visible = mode == "battle"

func refresh() -> void:
	update_status()
	var next_key := JSON.stringify([mode,zone,area,guardian_defeated,completed,focus,salves,seals,busy,active,party,enemy,special_battle_kind,opponent_slot,guardian_battle,combat_states,enemy_status])
	if next_key == actions_key:
		queue_redraw()
		return
	actions_key = next_key
	var old_focus := get_viewport().gui_get_focus_owner()
	var focus_index := old_focus.get_index() if old_focus != null and old_focus.get_parent() == buttons else 0
	if battle_layout != (mode == "battle"):
		action_scroll.remove_child(buttons)
		buttons.queue_free()
		battle_layout = mode == "battle"
		if battle_layout:
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation",8)
			grid.add_theme_constant_override("v_separation",8)
			buttons = grid
		else:
			buttons = VBoxContainer.new()
			buttons.add_theme_constant_override("separation",9)
		buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_scroll.add_child(buttons)
	action_scroll.position = Vector2(792,320) if battle_layout else Vector2(800,338)
	action_scroll.size = Vector2(332,362) if battle_layout else Vector2(315,344)
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	var p: Dictionary = party[active]
	var s: Dictionary = SPECIES[int(p.species)]
	if mode == "battle":
		var moves: Array = Moves.list(s)
		for slot in [0,2,1]:
			var move: Dictionary = moves[slot]
			var label := ("攻击 / " if slot == 0 else "")+str(move.name)+"\n%s ×%.2f / %d能" % [TYPES[int(move.element)],Elements.multiplier(int(move.element),SPECIES[int(enemy.species)].elements),move.cost]
			add_button(label,turn.bind("attack" if slot == 0 else "skill" if slot == 2 else "move:1"))
			var button: Button = buttons.get_child(buttons.get_child_count()-1)
			button.tooltip_text = Moves.description(move,s)
			button.disabled = busy or focus < int(move.cost)
		battle_status.text = "定位："+str(s.role)+" · 对方 [%s] · 能量 %d/3" % [Elements.names(SPECIES[int(enemy.species)].elements),enemy_focus]+"\n同伴："+Signature.status_text(current_status())+"\n对方："+Signature.status_text(enemy_status)
		add_button("防御\n能量 +1", turn.bind("guard"))
		add_button("药草 ×%d\n恢复生命" % salves, turn.bind("heal"))
		if not guardian_battle:
			add_button("安抚\n非致命 · 1能", turn.bind("soothe"))
		add_button("捕捉伙伴\n成功率 %d%%" % int(capture_chance()*100) if not guardian_battle else "导师不可捕捉", turn.bind("capture"))
		add_button("撤离战斗", turn.bind("flee"))
		if party.size() > 1: add_button("切换伙伴\n查看随行队伍",show_battle_party)
		for child in buttons.get_children():
			if child is Button and child.text.begins_with("捕捉伙伴") or child is Button and child.text == "导师不可捕捉": child.disabled = busy or guardian_battle or seals <= 0
			elif child is Button and child.text.begins_with("药草"): child.disabled = busy or salves <= 0
			elif child is Button and child.text.begins_with("安抚"): child.disabled = busy or focus <= 0
	else:
		add_button("在营地休息 [E]", rest)
		add_button("宠物背包 / 队伍与后备", show_backpack)
		add_button("与身边的人交谈 [R]", interact_nearby)
		add_button("任务日志 / 追踪目标 [J]",show_quest_journal)
		add_button("本区地形 / 路线 [M]",show_local_map)
		add_button("训练师资料与章节回顾",show_character)
		add_button("研究员档案", show_character)
		add_button("世界地图 / 9 个区域", show_world_map)
		add_button("灵兽图鉴 / 108 种灵兽", open_dex)
		add_button("旅程菜单 [Esc]", show_pause)
		if guardian_defeated and zone < 2:
			add_button("出发 → " + str(ISLANDS[zone+1].name), travel.bind(zone+1))
		for island in range(zone):
			add_button("返回 " + str(ISLANDS[island].name), travel.bind(island))
		if zone < 2 and completed[zone] and completed[zone+1]:
			add_button("前往 " + str(ISLANDS[zone+1].name), travel.bind(zone+1))
	for i in range(party.size()):
		if i != active and mode == "explore":
			add_button("换上 %s\n生命 %d/%d" % [SPECIES[int(party[i].species)].name, party[i].hp, party[i].max_hp], switch_to.bind(i))
	if mode == "battle" and buttons.get_child_count() > 0 and not busy:
		buttons.get_child(clampi(focus_index,0,buttons.get_child_count()-1)).grab_focus()
	queue_redraw()

func discovered() -> int:
	return known.size()

func _process(delta: float) -> void:
	if quitting: return
	if modal == null: seconds_played += delta
	companion_visual = companion_visual.lerp(companion_target,minf(1,delta*12)) if not reduce_motion else companion_target
	visual_player = visual_player.lerp(Vector2(player),minf(1,delta*18)) if not reduce_motion else Vector2(player)
	walk_time += delta
	impact_left = maxf(0,impact_left-delta)
	queue_redraw()
	step_timer -= delta
	if modal != null or mode != "explore": return
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
	if area == 1: return (p.x >= 4 and p.x <= 9 and p.y >= 1 and p.y <= 4) or (p.x >= 12 and p.y >= 6)
	if area == 2: return (p.x >= 5 and p.x <= 9 and p.y >= 6) or (p.x >= 12 and p.x <= 16 and p.y <= 4)
	if zone == 1: return (p.x >= 4 and p.x <= 8 and p.y >= 6 and p.y <= 9) or (p.x >= 12 and p.x <= 16 and p.y <= 4)
	if zone == 2: return (p.x >= 4 and p.x <= 9 and p.y <= 4) or (p.x >= 13 and p.y >= 6)
	if p.y == 5 or (p.x == 15 and p.y <= 5): return false
	return (p.x >= 5 and p.x <= 10 and p.y >= 3 and p.y <= 8) or (p.x >= 13 and p.y >= 6)

func move_player(d: Vector2i) -> void:
	var target := player + d
	if not is_land(target): return
	if target == Vector2i(3,4):
		talk_keeper()
		return
	if area > 0 and target == field_npc_position():
		talk_field_npc()
		return
	if target in obstacle_tiles() or target == Vector2i(2,5): return
	companion_target = Vector2(player)
	player = target
	steps_walked += 1
	if find_relic():
		refresh()
		return
	if player == Vector2i(15, 2):
		if completed.count(true) == 3 and zone == 2 and area == 2 and not story_flags.get("parents_rescued",false):
			start_special_battle("rescue")
			return
		if zone == 2 and area == 0 and story_flags.get("parents_rescued",false) and not story_flags.get("champion",false):
			start_special_battle("championship")
			return
		if guardian_defeated: message = "本地区资格已完成。按 J 查看下一阶段，或继续调查伙伴。"
		elif fragments >= 3 and area == 0: start_battle(int(ISLANDS[zone].boss), true)
		else: message = "地区导师在%s赛场，需要 3 资格积分。按 J 查看任务区域。" % AREAS[zone][0]
	elif is_grass(player) and rng.randf() < 0.23:
		start_battle(pick_encounter())
	elif player.distance_to(Vector2i(2, 5)) <= 1:
		message = "营地：按 E 恢复全队生命，并补给至 8 张捕捉胶囊。"
	refresh()

func start_battle(id: int, guardian: bool = false) -> void:
	battle_id += 1
	special_battle_kind = ""
	opponent_roster.clear()
	opponent_slot = 0
	busy = false
	mode = "battle"
	guardian_battle = guardian
	enemy = creature(id, int(ISLANDS[zone].level) if guardian else rng.randi_range(1+zone*2+area, 2+zone*2+area))
	focus = 3
	enemy_round = 0
	enemy_focus = 3
	combat_states.clear()
	enemy_status = Signature.state()
	salves = 3
	audio.play_track("guardian" if guardian else "battle")
	audio.sfx("hit")
	message = ("地区导师派出了伙伴！" if guardian else "草丛中出现了 " + str(SPECIES[id].name) + "！")
	refresh()

func current_status() -> Dictionary:
	if not combat_states.has(active): combat_states[active] = Signature.state()
	return combat_states[active]

func effectiveness(attacker: int, defender: int) -> float:
	return Elements.single(attacker,defender)

func turn(action: String) -> void:
	if mode != "battle" or busy or quitting: return
	var p: Dictionary = party[active]
	var s: Dictionary = SPECIES[int(p.species)]
	var e: Dictionary = SPECIES[int(enemy.species)]
	var move: Dictionary = {}
	var slots: Array = Moves.list(s)
	if action == "attack": move = slots[0]
	elif action == "skill": move = slots[2]
	elif action == "move:1": move = slots[1]
	elif action not in ["flee","capture","soothe","guard","heal"]: return
	var signature := not move.is_empty() and bool(move.signature)
	guarding = false
	match action:
		"flee":
			mode = "explore"
			audio.play_track("island_"+str(zone))
			message = "你安全撤回小径。"
			refresh()
			return
		"capture":
			if guardian_battle:
				message = "训练师的伙伴不能捕捉。"
				refresh()
				return
			if seals <= 0 or reserve.size() >= 200:
				message = "捕捉胶囊不足或储备已满（200 只），请回营地整理。"
				refresh()
				return
			seals -= 1
			var chance := capture_chance()
			if rng.randf() < chance:
				if animations_enabled:
					var capture_battle := battle_id
					busy = true
					impact_left = 0.6
					impact_enemy = true
					floating_text = "伙伴登记成立"
					audio.sfx("bell")
					refresh()
					await get_tree().create_timer(0.55).timeout
					if quitting or capture_battle != battle_id: return
					busy = false
				if not known.has(int(enemy.species)): known.append(int(enemy.species))
				if party.size() < 6: party.append(enemy.duplicate(true))
				else: reserve.append(enemy.duplicate(true))
				finish_battle("伙伴登记成立！" + str(e.name) + " 加入了队伍。")
				return
			message = "共鸣尚不稳定。降低对方生命会提高成功率。"
		"soothe":
			if focus <= 0:
				message = "能量不足，普通攻击或防御可恢复能量。"
				refresh()
				return
			focus -= 1
			enemy.hp = maxi(1,int(enemy.hp)-maxi(1,int(enemy.max_hp)/4))
			message = "你以伙伴指令安抚对方，留下了捕捉伙伴的机会。"
			impact_left = 0.42
			impact_enemy = true
			floating_text = "共鸣"
		"guard":
			focus = mini(3, focus+1)
			guarding = true
			if int(s.trait) == 2: p.hp = mini(int(p.max_hp),int(p.hp)+4)
			message = "你凝聚能量，抵御下一次攻击。"
		"heal":
			if salves <= 0:
				message = "本场药草已经用尽。"
				refresh()
				return
			salves -= 1
			p.hp = mini(int(p.max_hp), int(p.hp)+(30 if int(s.trait) == 5 else 24))
			message = "药草恢复了 24 点生命。"
		_:
			if focus < int(move.cost):
				message = "能量不足。普通攻击或防御可以恢复能量。"
				refresh()
				return
			focus = focus-int(move.cost) if int(move.cost) > 0 else mini(3, focus+(2 if int(s.trait) == 7 else 1))
			var element_mult := Elements.multiplier(int(move.element),e.elements)
			var mult := float(move.scale)*element_mult
			if int(s.trait) == 1 and int(p.hp)*2 < int(p.max_hp): mult *= 1.25
			if int(s.trait) == 6 and signature and int(enemy.hp)*2 > int(enemy.max_hp): mult *= 1.2
			var damage := maxi(1, int((int(s.power) + int(p.level)*2) * mult) + rng.randi_range(-2, 2))
			if signature and int(s.trait) in [0,3]: p.hp = mini(int(p.max_hp),int(p.hp)+(4 if int(s.trait) == 0 else 8))
			if signature and int(s.trait) == 8: guarding = true
			if signature: damage += Signature.bonus(s,enemy,int(p.hp)*2 <= int(p.max_hp))
			damage = Signature.direct_damage(damage,current_status(),enemy_status)
			if signature:
				Signature.apply(s,p,current_status(),enemy_status,int(p.hp)*2 <= int(p.max_hp))
				if s.skill_kind == "focus": focus = mini(3,focus+1)
			audio.sfx("hit")
			enemy.hp = maxi(0, int(enemy.hp) - damage)
			impact_left = 0.42
			impact_enemy = true
			floating_text = "−"+str(damage)
			message = "%s [%s] · %s，造成 %d 点伤害。" % [move.name,TYPES[int(move.element)],Elements.hint(element_mult),damage]
			if int(enemy.hp) <= 0:
				finish_battle("战斗胜利！")
				return
	var turn_battle := battle_id
	busy = true
	refresh()
	if animations_enabled: await get_tree().create_timer(0.42).timeout
	if quitting or turn_battle != battle_id: return
	if mode == "battle": enemy_turn()
	busy = false
	refresh()

func enemy_turn() -> void:
	var p: Dictionary = party[active]
	enemy_round += 1
	var enemy_tick: Dictionary = Signature.tick(enemy,enemy_status)
	if int(enemy_tick.damage) > 0: message += " 对方侵蚀 −%d。" % enemy_tick.damage
	if int(enemy.hp) <= 0:
		finish_battle("持续效果奏效，战斗胜利！")
		return
	var player_tick: Dictionary = Signature.tick(p,current_status())
	if int(player_tick.damage) > 0: message += " 同伴侵蚀 −%d。" % player_tick.damage
	if int(player_tick.healing) > 0: message += " 润泽 +%d。" % player_tick.healing
	var enemy_species: Dictionary = SPECIES[int(enemy.species)]
	var enemy_moves: Array = Moves.list(enemy_species)
	var move: Dictionary = enemy_moves[2] if enemy_round % 3 == 0 and enemy_focus >= 2 else enemy_moves[0]
	# An affordable coverage move is preferred when its matchup is strictly better.
	if enemy_round % 3 != 0 and enemy_focus >= 1 and Elements.multiplier(int(enemy_moves[1].element),SPECIES[int(p.species)].elements) > Elements.multiplier(int(move.element),SPECIES[int(p.species)].elements):
		move = enemy_moves[1]
	enemy_focus = enemy_focus-int(move.cost) if int(move.cost) > 0 else mini(3,enemy_focus+1)
	var element_mult := Elements.multiplier(int(move.element),SPECIES[int(p.species)].elements)
	var mult := float(move.scale)*element_mult
	var damage := maxi(1,int((int(enemy_species.power)+int(enemy.level))*mult))
	if bool(move.signature): damage += Signature.bonus(enemy_species,p,int(enemy.hp)*2 <= int(enemy.max_hp))
	if guardian_battle and enemy_round % 3 == 0:
		damage = int(damage*1.4)
		message += " 导师蓄力释放！"
	message += " 对方使用 %s [%s]，%s。" % [move.name,TYPES[int(move.element)],Elements.hint(element_mult)]
	if int(SPECIES[int(p.species)].trait) == 4: damage = maxi(1,damage-2)
	if guarding: damage = maxi(1, damage / 3)
	damage = Signature.direct_damage(damage,enemy_status,current_status())
	if bool(move.signature):
		Signature.apply(enemy_species,enemy,enemy_status,current_status(),int(enemy.hp)*2 <= int(enemy.max_hp))
		if enemy_species.skill_kind == "focus": enemy_focus = mini(3,enemy_focus+1)
	p.hp = maxi(0, int(p.hp) - damage)
	impact_left = 0.42
	impact_enemy = false
	floating_text = "−"+str(damage)
	message += " 对方反击 %d 点。" % damage
	if int(p.hp) <= 0:
		for i in range(party.size()):
			if int(party[i].hp) > 0:
				active = i
				message += " 同伴接替了战斗。"
				refresh()
				return
		mode = "explore"
		player = Vector2i(2, 6)
		visual_player = Vector2(player)
		companion_target = Vector2(player)+Vector2(0,1)
		companion_visual = companion_target
		heal_party()
		audio.play_track("island_"+str(zone))
		message = "队伍失去战斗能力。营地救援后已恢复，旅程可以继续。"
	refresh()

func finish_battle(text: String) -> void:
	if guardian_battle and opponent_slot+1 < opponent_roster.size():
		opponent_slot += 1
		enemy = opponent_roster[opponent_slot].duplicate(true)
		enemy_status = Signature.state()
		enemy_focus = 3
		message = "对方一名伙伴退出战斗，派出了 %s（%d / %d）。药草与能量不会重置。" % [SPECIES[int(enemy.species)].name,opponent_slot+1,opponent_roster.size()]
		refresh()
		return
	mode = "explore"
	audio.play_track("island_"+str(zone))
	audio.sfx("win")
	wins += 1
	fragments = mini(3, fragments + 1)
	crystals[zone] = fragments
	var p: Dictionary = party[active]
	p.xp = int(p.xp) + 1
	if int(p.xp) >= 3:
		p.xp = 0
		if int(p.level) < 99:
			p.level = int(p.level)+1
			p.max_hp = int(p.max_hp)+6
			p.hp = p.max_hp
			text += " 同伴升级，生命恢复！"
	if guardian_battle:
		if special_battle_kind.is_empty() and not completed[zone]:
			guardian_defeated = true
			completed[zone] = true
			for companion in party:
				if int(companion.level) < 99:
					companion.level += 1
					companion.max_hp += 6
			text += " 导师指导：全队等级 +1。"
		text += " 训练师挑战获胜！"
		heal_party()
	var collection_complete := discovered() == PET_COUNT and not collection_rewarded
	if collection_complete:
		collection_rewarded = true
		text += " 108 种图鉴完成，获得称号：图鉴大师！"
	var special_ending := ""
	if special_battle_kind == "rescue":
		story_flags["parents_rescued"] = true
		special_ending = Story.RESCUE_END
	elif special_battle_kind == "championship":
		story_flags["champion"] = true
		special_ending = Story.CHAMPION_END
	special_battle_kind = ""
	message = text + " 获得 1 资格积分。"
	save_game(false)
	refresh()
	if not special_ending.is_empty(): show_story(special_ending)
	elif guardian_battle: show_story(str(Story.CHAPTERS[zone].ending))
	elif collection_complete: show_story("你听见了地区所有的回声。108 种灵兽的名字，已经写进训练师的研究手记。\n\n称号解锁：图鉴大师\n每一次相遇，都让下一段旅程更值得期待。")

func switch_to(index: int) -> void:
	if busy or int(party[index].hp) <= 0: return
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
		message = "全队恢复了精神，捕捉胶囊补给完毕。"
		save_game(false)
	refresh()

func save_game(notify: bool = true) -> void:
	var file := FileAccess.open(SAVE_PATH+".tmp", FileAccess.WRITE)
	if file == null:
		message = "存档失败：无法写入用户目录。"
		refresh()
		return
	file.store_string(JSON.stringify({"version":2,"story_flags":story_flags,"tracked_goal":tracked_goal,"zone":zone,"area":area,"steps":steps_walked,"seconds":seconds_played,"completed":completed,"crystals":crystals,"relics":relics,"collection_rewarded":collection_rewarded,"keeper_rewards":keeper_rewards,"party":party,"reserve":reserve,"known":known,"active":active,"seals":seals,"fragments":fragments,"wins":wins,"guardian":guardian_defeated,"x":player.x,"y":player.y}))
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
	var data := read_valid_save(SAVE_PATH)
	var recovered := false
	if data.is_empty():
		data = read_valid_save(SAVE_PATH+".bak")
		recovered = not data.is_empty()
	if data.is_empty():
		message = "存档无法读取，当前旅程未被覆盖。可从标题开始新旅程。"
		return
	story_flags = data.get("story_flags",{})
	tracked_goal = str(data.get("tracked_goal","main"))
	# No live state is changed until the entire save has passed validation.
	party = data.party
	reserve = data.get("reserve",[])
	known = []
	for id in data.get("known",[0]):
		if not known.has(int(id)): known.append(int(id))
	completed = data.completed
	crystals = data.crystals
	relics = data.get("relics",[false,false,false,false,false,false])
	zone = int(data.get("zone",0))
	area = int(data.get("area",0))
	steps_walked = maxi(0,int(data.get("steps",0)))
	seconds_played = maxf(0,float(data.get("seconds",0)))
	active = clampi(int(data.get("active",0)),0,party.size()-1)
	seals = clampi(int(data.get("seals",8)),0,9999)
	fragments = clampi(int(crystals[zone]),0,3)
	wins = maxi(0,int(data.get("wins",0)))
	guardian_defeated = bool(completed[zone])
	collection_rewarded = bool(data.get("collection_rewarded",false))
	keeper_rewards = data.get("keeper_rewards",[false,false,false])
	player = Vector2i(clampi(int(data.get("x",2)),1,16),clampi(int(data.get("y",5)),1,9))
	if player in obstacle_tiles() or player == Vector2i(2,5) or not is_land(player): player = Vector2i(2,6)
	message = "主存档损坏，已恢复上一份备份。" if recovered else "已恢复上次的旅程。"

func read_valid_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var raw := FileAccess.get_file_as_string(path)
	if raw.length() > 262144: return {}
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {}
	var data = parser.data
	if not data is Dictionary or data.get("version") != 2: return {}
	for key in ["zone","area","active","seals","wins","x","y","steps","seconds"]:
		var value = data.get(key,0)
		if not (value is int or value is float): return {}
		if not is_finite(float(value)) or absf(float(value)) > 1000000: return {}
	if int(data.get("zone",0)) < 0 or int(data.get("zone",0)) > 2: return {}
	if int(data.get("area",0)) < 0 or int(data.get("area",0)) > 2: return {}
	if not data.get("collection_rewarded",false) is bool: return {}
	var flags = data.get("story_flags",{})
	if not flags is Dictionary or flags.size() > 128: return {}
	for key in flags:
		if not key is String or key.length() > 80 or not flags[key] is bool: return {}
	if data.get("tracked_goal","main") not in ["main","camp","field"]: return {}
	var loaded = data.get("party",[])
	var saved_reserve = data.get("reserve",[])
	if not loaded is Array or loaded.is_empty() or loaded.size() > 6: return {}
	if not saved_reserve is Array or saved_reserve.size() > 200: return {}
	for p in loaded+saved_reserve:
		if not valid_creature(p): return {}
	var saved_known = data.get("known",[0])
	if not saved_known is Array or saved_known.size() > PET_COUNT: return {}
	for id in saved_known:
		if not (id is int or id is float) or int(id) < 0 or int(id) >= PET_COUNT: return {}
	for key in ["completed","crystals","relics","keeper_rewards"]:
		var values = data.get(key,[false,false,false,false,false,false] if key == "relics" else [false,false,false] if key == "keeper_rewards" else [])
		if not values is Array or values.size() != (6 if key == "relics" else 3): return {}
		for value in values:
			if key == "crystals":
				if not (value is int or value is float) or int(value) < 0 or int(value) > 3: return {}
			elif not value is bool: return {}
	if flags.get("parents_rescued",false) and data.completed.count(true) < 3: return {}
	if flags.get("champion",false) and not flags.get("parents_rescued",false): return {}
	return data

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
			var border := not is_land(Vector2i(x,y))
			draw_rect(Rect2(pos,Vector2(TILE,TILE)),(Color("263f37") if zone == 0 else Color("503c36") if zone == 1 else Color("29394c")) if border else ISLANDS[zone].grass if is_grass(Vector2i(x,y)) else ISLANDS[zone].ground.lightened(area*0.055))
			if border:
				draw_rect(Rect2(pos+Vector2(6,9),Vector2(14,8)),Color("3b5043") if zone != 1 else Color("6a5145"))
				draw_rect(Rect2(pos+Vector2(22,25),Vector2(10,7)),Color("32463c") if zone != 1 else Color("60483f"))
			elif is_grass(Vector2i(x,y)):
				WorldArt.draw_object(self,1,pos+Vector2(20,39),Vector2(36,30))
			elif (x*3+y*7)%4 == 0:
				draw_rect(Rect2(pos+Vector2(8,12),Vector2(3,2)),Color(0.3,0.4,0.3,0.16))
	# Worn paths, shore stones, and island-specific foliage.
	for x in range(1,17):
		draw_rect(Rect2(ORIGIN+Vector2(x,5)*TILE+Vector2(0,9),Vector2(40,22)),Color("c5b797"))
	for y in range(2,6): draw_rect(Rect2(ORIGIN+Vector2(15,y)*TILE+Vector2(9,0),Vector2(22,40)),Color("c5b797"))
	for tile in obstacle_tiles():
		if area > 0 and tile == field_npc_position(): continue
		if is_land(tile): draw_tree(ORIGIN+Vector2(tile)*TILE+Vector2(20,23),zone)
	for y in range(1,10):
		for x in range(1,17):
			if (x*7+y*13+zone)%17 == 0 and not is_grass(Vector2i(x,y)) and x != 11 and is_land(Vector2i(x,y)):
				var flower := ORIGIN+Vector2(x,y)*TILE+Vector2(7,12)
				if is_land(Vector2i(x,y)): WorldArt.draw_object(self,2,flower+Vector2(6,9),Vector2(17,14))
				draw_rect(Rect2(flower,Vector2(4,7)),Color("507c65"))
				draw_rect(Rect2(flower+Vector2(-2,-2),Vector2(8,5)),Color("e8d7a1") if zone != 1 else Color("c7b3d8"))
	for tile in guide_path:
		draw_circle(ORIGIN+Vector2(tile)*TILE+Vector2(20,28),2,Color("f5dba2"))
	for i in range(2):
		if area == 0 and not relics[zone*2+i]:
			var relic_pos := ORIGIN+Vector2(relic_position(i))*TILE+Vector2(20,20)
			var glow := 3+sin(walk_time*4)*2
			WorldArt.draw_object(self,7,relic_pos+Vector2(0,20),Vector2(29,38))
			draw_circle(relic_pos+Vector2(0,-glow),2,Color("d7fff0"))
	# Camp and ancient beacon.
	var camp := ORIGIN + Vector2(2,5)*TILE
	WorldArt.draw_object(self,3,camp+Vector2(20,40),Vector2(62,47))
	WorldArt.draw_object(self,6,camp+Vector2(53,38),Vector2(16,28))
	var arena := ORIGIN+Vector2(15,2)*TILE
	draw_rect(Rect2(arena+Vector2(-16,-10),Vector2(72,58)),Color("425a69"))
	draw_rect(Rect2(arena+Vector2(-10,-4),Vector2(60,46)),Color("e5d8b3"))
	draw_rect(Rect2(arena+Vector2(10,13),Vector2(20,29)),Color("3a6875"))
	for offset in [-12,45]:
		draw_line(arena+Vector2(offset,-9),arena+Vector2(offset,-33),Color("ece1be"),2)
		draw_colored_polygon(PackedVector2Array([arena+Vector2(offset,-33),arena+Vector2(offset+14,-28),arena+Vector2(offset,-22)]),Color("dc9482") if area == 2 and zone == 2 else Color("8cc9af"))
	var map_font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	draw_string(map_font,ORIGIN+Vector2(54,193),"营地",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
	draw_string(map_font,ORIGIN+Vector2(580,64),"研究站" if zone == 2 and area == 2 else "赛场" if area == 0 else "巡查站",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
	preload("res://scripts/pixel_art.gd").draw_creature(self,ORIGIN+companion_visual*TILE+Vector2(20,25),int(party[active].species),0.32,0 if reduce_motion else walk_time)
	var keeper_pos := ORIGIN+Vector2(3,4)*TILE
	draw_texture_rect(preload("res://scripts/pixel_art.gd").keeper_token(),Rect2(keeper_pos-Vector2(7,12),Vector2(54,54)),false,Color(0.72,0.86,1))
	draw_string(map_font,keeper_pos+Vector2(-2,-5),"阿岚",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
	if area > 0:
		var npc_pos := ORIGIN+Vector2(field_npc_position())*TILE
		draw_texture_rect(preload("res://scripts/pixel_art.gd").hero_portrait() if area == 1 else preload("res://scripts/pixel_art.gd").keeper_token(),Rect2(npc_pos-Vector2(7,12),Vector2(54,54)),false,Color("c1dcac") if area == 1 else Color("e3c19e"))
		draw_string(map_font,npc_pos+Vector2(-8,-7),"茵禾" if area == 1 else "乔渡",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff0c6"))
		if not story_flags.get("field_reward_%d_%d" % [zone,area],false): draw_string(map_font,npc_pos+Vector2(14,-26),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("ffe49b"))
	var hero := ORIGIN + visual_player*TILE
	draw_string(map_font,hero+Vector2(-1,-8),"洛汐",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff0c6"))
	draw_rect(Rect2(hero+Vector2(10,30),Vector2(24,6)),Color("50665a"))
	draw_texture_rect(preload("res://scripts/pixel_art.gd").hero_portrait(false,1+int(walk_time*12)%2 if visual_player.distance_to(Vector2(player)) > 0.04 else 0),Rect2(hero-Vector2(7,12),Vector2(54,54)),false)

func draw_beast(pos: Vector2, id: int, scale_factor: float) -> void:
	draw_ellipse_shadow(pos+Vector2(0,49)*scale_factor,Vector2(50,10)*scale_factor)
	preload("res://scripts/pixel_art.gd").draw_creature(self,pos,id,scale_factor,0.0 if reduce_motion else walk_time)

func draw_ellipse_shadow(pos: Vector2, size_value: Vector2) -> void:
	draw_set_transform(pos,0,Vector2(1,size_value.y/size_value.x))
	draw_circle(Vector2.ZERO,size_value.x,Color("243b48"))
	draw_set_transform(Vector2.ZERO)

func draw_battle() -> void:
	draw_rect(Rect2(40,146,720,440),ISLANDS[zone].water.lightened(0.05))
	draw_rect(Rect2(420,155,321,104),Color("172f3d"))
	draw_rect(Rect2(58,475,332,67),Color("172f3d"))
	draw_rect(Rect2(800,286,306,9),Color("102430"))
	var ally: Dictionary = party[active]
	draw_rect(Rect2(800,286,306*float(ally.hp)/float(ally.max_hp),9),Color("83d3ad") if float(ally.hp)/float(ally.max_hp) > 0.3 else Color("e99a83"))
	for i in range(5): draw_rect(Rect2(40,146+i*49,720,1),Color("2b4c59"))
	var shake := sin(impact_left*60)*4*pow(impact_left/0.42,2) if impact_left > 0 and not reduce_motion else 0.0
	draw_beast(Vector2(220+shake if not impact_enemy else 220.0,382),int(party[active].species),1.7)
	draw_beast(Vector2(565+shake if impact_enemy else 565.0,355),int(enemy.species),1.5)
	var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
	draw_string(font,Vector2(72,500),str(SPECIES[int(ally.species)].name)+" · "+Elements.names(SPECIES[int(ally.species)].elements),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f1dfb6"))
	draw_rect(Rect2(72,516,290,8),Color("102430"))
	draw_rect(Rect2(72,516,290*float(ally.hp)/float(ally.max_hp),8),Color("83d3ad"))
	if impact_left > 0:
		draw_string(font,Vector2(550,270-impact_left*50) if impact_enemy else Vector2(210,365-impact_left*50),floating_text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("ffe0b0"))
	draw_string(font,Vector2(432,180),str(SPECIES[int(enemy.species)].name)+"  Lv."+str(enemy.level),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f3e5c1"))
	draw_rect(Rect2(432,196,260,12),Color("172b38"))
	draw_rect(Rect2(432,196,260*float(enemy.hp)/float(enemy.max_hp),12),Color("86d3a2"))
	draw_string(font,Vector2(432,235),"HP %d/%d · %s · %d能" % [enemy.hp,enemy.max_hp,Elements.names(SPECIES[int(enemy.species)].elements),enemy_focus],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
	if guardian_battle:
		draw_string(font,Vector2(65,180),"导师蓄力：下一回合重击！" if enemy_round % 3 == 2 else "导师每三回合蓄力重击",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f4b797"))
	draw_string(font,Vector2(70,560),"克制 ×1.5 · 双弱点最高 ×2 · 按招式属性判定",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b0c6c7"))

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
		elif event.physical_keycode == KEY_E and modal == null and mode == "explore": rest()
		elif event.physical_keycode == KEY_R and modal == null and mode == "explore": interact_nearby()
		elif event.physical_keycode == KEY_J and modal == null and mode == "explore": show_quest_journal()
		elif event.physical_keycode == KEY_M and modal == null and mode == "explore": show_local_map()

func close_modal() -> void:
	if modal != null:
		remove_child(modal)
		modal.queue_free()
		modal = null
		if audio != null: audio.play_track("island_"+str(zone) if mode == "explore" else "guardian" if guardian_battle else "battle")

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
	scroll.follow_focus = true
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
	if not get_viewport().gui_get_focus_owner() or not modal.is_ancestor_of(get_viewport().gui_get_focus_owner()): b.grab_focus()

func show_title() -> void:
	open_modal("星 野 伙 伴", "S T A R W I L D   /   v0.9.0\n\n记录每一次相遇，成为值得信赖的训练师。\n三地资格 · 父母救援 · 冠军赛 · 108 种灵兽\nWASD 移动 · J 任务 · M 地图 · R 交谈")
	audio.play_track("title")
	var shade: ColorRect = modal.get_child(0)
	shade.color = Color(0.02,0.05,0.1,0.16)
	var panel: PanelContainer = modal.get_child(1)
	panel.position = Vector2(650,38)
	panel.size = Vector2(460,644)
	panel.set_deferred("size",Vector2(460,644))
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.045,0.09,0.15,0.87)
	panel.add_theme_stylebox_override("panel",style)
	var scroll: ScrollContainer = panel.get_child(0)
	scroll.custom_minimum_size = Vector2(394,588)
	modal_body.get_child(0).add_theme_font_size_override("font_size",38)
	modal_body.get_child(1).custom_minimum_size.x = 390
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/art/title_starwild.png")
	backdrop.size = Vector2(1152,720)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	modal.add_child(backdrop)
	modal.move_child(backdrop,0)
	var portraits := HBoxContainer.new()
	portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	portraits.add_theme_constant_override("separation",36)
	for id in [0,1,2]:
		var portrait := TextureRect.new()
		portrait.texture = preload("res://scripts/pixel_art.gd").portrait(id)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.custom_minimum_size = Vector2(84,78)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portraits.add_child(portrait)
	modal_body.add_child(portraits)
	if FileAccess.file_exists(SAVE_PATH): modal_button("继续旅程",close_modal)
	modal_button("开始新的旅程",confirm_new_game)
	modal_button("设置与操作说明",show_settings)
	modal_button("制作与版权",show_credits)
	modal_button("退出游戏",quit_game)

func confirm_new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		open_modal("新的旅程", "开始新旅程会覆盖当前存档。旧存档会保留一份 .bak 备份。")
		modal_button("确认开始",new_game)
		modal_button("返回",show_title)
	else: new_game()

func new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(SAVE_PATH,SAVE_PATH+".bak")
	battle_id += 1
	busy = false
	party = [creature(0)]
	story_flags.clear()
	tracked_goal = "main"
	reserve = []
	known = [0]
	active = 0
	player = Vector2i(2,6)
	zone = 0
	area = 0
	completed = [false,false,false]
	crystals = [0,0,0]
	relics = [false,false,false,false,false,false]
	fragments = 0
	guardian_defeated = false
	collection_rewarded = false
	keeper_rewards = [false,false,false]
	guardian_battle = false
	special_battle_kind = ""
	mode = "explore"
	reset_visual_positions()
	wins = 0
	steps_walked = 0
	seconds_played = 0
	seals = 8
	message = "第一位同伴苔芽兽，已经在营地等你。"
	save_game(false)
	refresh()
	show_story(str(Story.CHAPTERS[0].intro))

func show_story(text: String) -> void:
	open_modal(str(Story.CHAPTERS[zone].title),text)
	modal_button("让旅程继续",close_modal)

func show_pause() -> void:
	open_modal("训练师行囊", "进度：%d / 3 枚地区徽章  ·  图鉴 %d / 108\n%s" % [completed.count(true),discovered(),ISLANDS[zone].subtitle])
	modal_button("继续旅程",close_modal)
	if mode == "explore": modal_button("保存旅程",func(): save_game(); close_modal())
	modal_button("研究员档案",show_character)
	modal_button("图鉴",open_dex)
	modal_button("宠物背包",show_backpack)
	modal_button("任务日志与章节回顾",show_quest_journal)
	modal_button("属性克制手册",show_elements)
	modal_button("世界地图",show_world_map)
	modal_button("设置与操作说明",show_settings)
	modal_button("返回标题",show_title)
	modal_button("保存并退出" if mode == "explore" else "退出（回到最近自动存档）",quit_game)

func show_dex() -> void:
	var ids: Array = []
	for id in range(PET_COUNT):
		if dex_filter == 1 and not known.has(id): continue
		if dex_filter == 2 and known.has(id): continue
		ids.append(id)
	dex_page = clampi(dex_page,0,maxi(0,int((ids.size()-1)/9)))
	open_modal("伙伴图鉴", "已结识 %d / 108 · 第 %d / %d 页 · 点击查看详情" % [discovered(),dex_page+1,maxi(1,int(ceil(ids.size()/9.0)))])
	var panel: PanelContainer = modal.get_child(1)
	panel.position.y = 20
	panel.size.y = 680
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation",10)
	for spec in [["上一页",-1],["下一页",1]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(160,34)
		button.pressed.connect(change_dex_page.bind(int(spec[1])))
		button.disabled = (dex_page == 0 if int(spec[1]) < 0 else (dex_page+1)*9 >= ids.size())
		nav.add_child(button)
	var filter_button := Button.new()
	filter_button.text = ["全部","已结识","未结识"][dex_filter]+" / 切换"
	filter_button.custom_minimum_size = Vector2(200,34)
	filter_button.pressed.connect(cycle_dex_filter)
	nav.add_child(filter_button)
	modal_body.add_child(nav)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	for index in range(dex_page*9,mini(ids.size(),dex_page*9+9)):
		var id: int = ids[index]
		var owned := known.has(id)
		var card := Button.new()
		card.custom_minimum_size = Vector2(208,136)
		card.pressed.connect(show_pet_detail.bind(id))
		var image := TextureRect.new()
		image.name = "Portrait"
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.texture = preload("res://scripts/pixel_art.gd").portrait(id)
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not owned: image.modulate = Color(0.25,0.34,0.39,1)
		var content := VBoxContainer.new()
		content.name = "Content"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 5
		content.offset_right = -5
		content.offset_top = 5
		content.offset_bottom = -5
		image.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(image)
		var name_label := Label.new()
		name_label.text = "%03d  %s\n[%s]" % [id+1,SPECIES[id].name,Elements.names(SPECIES[id].elements)]
		name_label.custom_minimum_size.y = 40
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size",14)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(name_label)
		grid.add_child(card)
	modal_body.add_child(grid)
	if grid.get_child_count() > 0: grid.get_child(0).grab_focus()
	modal_button("返回旅程",close_modal)

func show_pet_detail(id: int) -> void:
	var species: Dictionary = SPECIES[id]
	var traits = Signature.PASSIVES
	open_modal("%03d · %s" % [id+1,species.name], "[%s] · %s\n栖息地：%s / %s\n出没：%s" % [Elements.names(species.elements),"已结识" if known.has(id) else "尚未捕捉伙伴",ISLANDS[int(species.island)].name,AREAS[int(species.island)][int(species.area)],"本区域草丛，全天可遇见"])
	var panel: PanelContainer = modal.get_child(1)
	panel.position.y = 20
	panel.size.y = 680
	var image := TextureRect.new()
	image.texture = preload("res://scripts/pixel_art.gd").portrait(id)
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(600,150)
	modal_body.add_child(image)
	var info_label := Label.new()
	info_label.text = "%s\n\n技能：%s\n特性：%s\n基础生命 %d · 基础攻击 %d" % [species.lore,Moves.catalogue(species),traits[int(species.trait)],species.max_hp,species.power]
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size.x = 650
	modal_body.add_child(info_label)
	modal_button("返回图鉴",show_dex)

func show_settings() -> void:
	open_modal("设置与操作", "WASD / 方向键：移动    E：营地休息    R：交谈\nJ：任务日志    M：本区地图    Esc：菜单 / 返回\n鼠标选择技能；Tab / 方向键切换焦点。\n\n每只伙伴最多两种属性，三项技能各有自己的属性。\n普通攻击与防御恢复能量；补盲技消耗 1，专属技消耗 2。\n训练师的伙伴不能捕捉。每战有 3 份药草，换宠消耗回合。\n所有物种都可在对应区域全天遇见；没有环境切换门槛。\n\n音量")
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = volume
	slider.custom_minimum_size.y = 30
	slider.value_changed.connect(func(value: float): volume=value; audio.set_volume(value); save_settings())
	modal_body.add_child(slider)
	var motion_toggle := CheckButton.new()
	motion_toggle.text = "减少动态效果（关闭晃动与待机浮动）"
	motion_toggle.button_pressed = reduce_motion
	motion_toggle.toggled.connect(func(value: bool): reduce_motion=value; save_settings())
	modal_body.add_child(motion_toggle)
	modal_button("切换全屏 / 窗口",toggle_fullscreen)
	modal_button("返回旅程",close_modal)

func toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio","volume",volume)
	cfg.set_value("accessibility","reduce_motion",reduce_motion)
	cfg.set_value("display","fullscreen",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	cfg.save("user://settings.cfg")

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		reduce_motion = bool(cfg.get_value("accessibility","reduce_motion",false))
		volume = clampf(float(cfg.get_value("audio","volume",0.65)),0,1)
		if bool(cfg.get_value("display","fullscreen",false)) and DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	audio.set_volume(volume)

func show_credits() -> void:
	open_modal("制作与版权", "星野伙伴 / Starwild\n游戏设计、代码与美术由 AI 辅助创作。\n宠物、场景物件、角色立绘及标题插画为 AI 生成/迭代素材。\n配乐与音效由项目内合成器生成。\n使用 Godot Engine 4.6.3（MIT）。\n字体：Noto Sans CJK（SIL Open Font License 1.1）。\n许可全文随源码与发行包提供。\n\n本游戏为独立原创项目，与其他怪物收集作品无隶属关系。\n当前版本不联网、不含内购、不采集遥测。")
	modal_button("返回",show_title)

func travel(destination: int) -> void:
	if mode != "explore" or destination < 0 or destination > 2: return
	if destination > 0 and not completed[destination-1]: return
	crystals[zone] = fragments
	zone = destination
	area = 0
	fragments = int(crystals[zone])
	guardian_defeated = bool(completed[zone])
	player = Vector2i(2,6)
	visual_player = Vector2(player)
	companion_target = Vector2(player)+Vector2(0,1)
	companion_visual = companion_target
	heal_party()
	message = "抵达" + str(ISLANDS[zone].name) + "，营地已准备好。"
	audio.play_track("island_"+str(zone))
	save_game(false)
	refresh()
	show_story(str(Story.CHAPTERS[zone].intro))

func quit_game() -> void:
	if quitting: return
	quitting = true
	busy = true
	for button in find_children("*","BaseButton",true,false): button.disabled = true
	if mode == "explore": save_game(false)
	audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func valid_creature(p: Variant) -> bool:
	if not p is Dictionary: return false
	for key in ["species","level","hp","max_hp","xp"]:
		if not p.has(key) or not (p[key] is int or p[key] is float): return false
	return int(p.species) >= 0 and int(p.species) < PET_COUNT and int(p.level) >= 1 and int(p.level) <= 99 and int(p.max_hp) > 0 and int(p.max_hp) <= 1000 and int(p.hp) >= 0 and int(p.hp) <= int(p.max_hp) and int(p.xp) >= 0 and int(p.xp) < 3

func show_roster() -> void:
	if mode != "explore" or player.distance_to(Vector2i(2,5)) > 1:
		message = "请回营地编队。队伍最多六只，新结识的灵兽会进入营地储备。"
		refresh()
		return
	open_modal("营地 · 同伴编队", "当前队伍 %d / 6，储备 %d / 200。\n点击储备灵兽与当前出战同伴交换；未满六只时会直接加入队伍。" % [party.size(),reserve.size()])
	reserve_page = clampi(reserve_page,0,maxi(0,int((reserve.size()-1)/12)))
	for i in range(reserve_page*12,mini(reserve.size(),reserve_page*12+12)):
		var p: Dictionary = reserve[i]
		modal_button("%s  Lv.%d  [%s]" % [SPECIES[int(p.species)].name,p.level,Elements.names(SPECIES[int(p.species)].elements)],inspect_reserve.bind(i))
	if reserve.is_empty():
		var text := Label.new()
		text.text = "暂无储备灵兽。队伍满员后，新的同伴会在这里等你。"
		modal_body.add_child(text)
	if reserve_page > 0: modal_button("上一箱",change_reserve_page.bind(-1))
	if (reserve_page+1)*12 < reserve.size(): modal_button("下一箱",change_reserve_page.bind(1))
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
			if event.button_index == JOY_BUTTON_X: show_quest_journal()
			elif event.button_index == JOY_BUTTON_Y: rest()

func obstacle_tiles() -> Array:
	var tiles: Array
	if zone == 1: tiles = [Vector2i(2,2),Vector2i(3,2),Vector2i(4,3),Vector2i(8,2),Vector2i(9,2),Vector2i(13,8),Vector2i(14,8),Vector2i(3,9)]
	elif zone == 2: tiles = [Vector2i(2,2),Vector2i(3,2),Vector2i(8,8),Vector2i(9,8),Vector2i(13,3),Vector2i(14,3),Vector2i(3,8),Vector2i(4,8)]
	else: tiles = [Vector2i(3,2),Vector2i(4,2),Vector2i(3,3),Vector2i(8,1),Vector2i(9,1),Vector2i(13,3),Vector2i(14,3),Vector2i(16,5),Vector2i(4,8),Vector2i(3,8),Vector2i(2,9)]
	if area > 0: tiles.append(field_npc_position())
	return tiles

func draw_tree(pos: Vector2, variant: int) -> void:
	if zone == 1:
		WorldArt.draw_object(self,2,pos+Vector2(0,14),Vector2(46,41),Color("d6aa8b"))
		return
	var tint := Color.WHITE if variant == 0 else Color(0.8,0.85,1) if variant == 1 else Color(1,0.91,0.77)
	WorldArt.draw_object(self,0,pos+Vector2(0,17),Vector2(48,62),tint)

func relic_position(index: int) -> Vector2i:
	var positions := [[Vector2i(7,2),Vector2i(14,8)],[Vector2i(6,8),Vector2i(13,1)],[Vector2i(6,3),Vector2i(14,7)]]
	return positions[zone][index]

func find_relic() -> bool:
	if area != 0: return false
	for i in range(2):
		if relics[zone*2+i] or player != relic_position(i): continue
		relics[zone*2+i] = true
		seals += 3
		for p in party: p.hp = mini(int(p.max_hp),int(p.hp)+12)
		var stories := ["青芽补给箱：母亲留下的记录说，先观察伙伴的习性，再决定如何靠近。", "父亲的便签：图鉴里的栖息地可以核对运输编号，别急着追求数量。", "赤岩补给箱：同一批伙伴被重复登记，调查员已经保留了原始清单。", "巡查记录：前往陌生地区前，检查胶囊和药草，准备不同属性的队伍。", "星原补给箱：研究站的保全室仍有人保护伙伴，三地资格齐全后可申请进入。", "父母的研究札记：真正强大的训练师，会让伙伴有选择留下或离开的自由。"]
		message = "发现调查补给箱：捕捉胶囊 +3，全队恢复 12 生命。"
		audio.sfx("bell")
		save_game(false)
		show_story(stories[zone*2+i])
		return true
	return false

func inspect_reserve(index: int) -> void:
	if index < 0 or index >= reserve.size(): return
	var p: Dictionary = reserve[index]
	open_modal(str(SPECIES[int(p.species)].name), "Lv.%d · 生命 %d / %d\n%s" % [p.level,p.hp,p.max_hp,SPECIES[int(p.species)].lore])
	modal_button("加入队伍 / 交换出战同伴",withdraw.bind(index))
	modal_button("放归伙伴（图鉴记录保留）",confirm_release.bind(index))
	modal_button("返回营地",show_roster)

func confirm_release(index: int) -> void:
	if index < 0 or index >= reserve.size(): return
	open_modal("让同伴回到野外", "确认与 %s 放归伙伴？这只灵兽将回到野外，图鉴记录会保留。" % SPECIES[int(reserve[index].species)].name)
	modal_button("确认解除",func(): reserve.remove_at(index); save_game(false); refresh(); show_roster())
	modal_button("保持伙伴登记",show_roster)

func encounter_pool(island: int = -1, region: int = -1, _legacy_phase: int = -1) -> Array:
	var pool: Array = []
	if island < 0: island = zone
	if region < 0: region = area
	for id in range(PET_COUNT):
		var s: Dictionary = SPECIES[id]
		if int(s.island) == island and int(s.area) == region: pool.append(id)
	return pool

func pick_encounter() -> int:
	var pool := encounter_pool()
	var missing: Array = []
	for id in pool:
		if not known.has(id): missing.append(id)
	if not missing.is_empty() and rng.randf() < 0.65: pool = missing
	return int(pool[rng.randi_range(0,pool.size()-1)])

func open_dex() -> void:
	dex_page = 0
	show_dex()

func cycle_dex_filter() -> void:
	dex_filter = (dex_filter+1)%3
	dex_page = 0
	show_dex()

func change_dex_page(direction: int) -> void:
	dex_page += direction
	show_dex()

func change_reserve_page(direction: int) -> void:
	reserve_page += direction
	show_roster()

func show_world_map() -> void:
	if mode != "explore":
		message = "请先结束战斗再打开区域地图。"
		return
	open_modal("训练师世界地图", "三个地区 · 九个生态区域 · 108 种灵兽\n当前：%s / %s\n每片区域有十二种伙伴，所有物种均可全天遇见。" % [ISLANDS[zone].name,AREAS[zone][area]])
	var chart := preload("res://scripts/ui_art.gd").new()
	chart.custom_minimum_size = Vector2(660,165)
	chart.completed = completed
	chart.current = zone
	modal_body.add_child(chart)
	for island in range(3):
		var unlocked := island == 0 or bool(completed[island-1])
		for region in range(3):
			var label := "%s · %s" % [ISLANDS[island].name,AREAS[island][region]]
			var recorded := 0
			for id in known:
				if int(SPECIES[id].island) == island and int(SPECIES[id].area) == region: recorded += 1
			label += " / %d / 12" % recorded
			label += " / 尚未解锁" if not unlocked else " / 当前区域" if zone == island and area == region else " / 前往营地"
			modal_button(label,visit_region.bind(island,region))
			modal_body.get_child(modal_body.get_child_count()-1).disabled = not unlocked
	modal_button("返回旅程",close_modal)

func visit_region(island: int, region: int) -> void:
	if mode != "explore" or island < 0 or island > 2 or region < 0 or region > 2: return
	if island > 0 and not completed[island-1]: return
	crystals[zone] = fragments
	zone = island
	area = region
	fragments = int(crystals[zone])
	guardian_defeated = bool(completed[zone])
	player = Vector2i(2,6)
	visual_player = Vector2(player)
	companion_target = Vector2(player)+Vector2(0,1)
	companion_visual = companion_target
	heal_party()
	message = "抵达%s。按 M 查看地形，按 J 查看任务，按 R 与身边的人交谈。" % AREAS[zone][area]
	close_modal()
	audio.play_track("island_"+str(zone))
	save_game(false)
	refresh()

func show_character() -> void:
	open_modal("洛汐 · 伙伴训练师", "她带着父母的研究手记出发，通过图鉴调查和训练师联赛寻找家人的下落。\n已有 %d 种伙伴加入她的图鉴。" % discovered())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",25)
	var portrait := TextureRect.new()
	portrait.texture = preload("res://scripts/pixel_art.gd").hero_portrait(true)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(230,300)
	row.add_child(portrait)
	var stats := Label.new()
	stats.text = "旅程时长  %d 分钟\n探索步数  %d 步\n捕捉伙伴  %d / 108 种\n取得徽章  %d / 3\n战斗与伙伴登记成功  %d 次\n发现补给箱  %d / 6\n完成生态委托  %d / 3" % [int(seconds_played/60),steps_walked,discovered(),completed.count(true),wins,relics.count(true),keeper_rewards.count(true)]
	if collection_rewarded: stats.text += "\n称号  图鉴大师"
	row.add_child(stats)
	modal_body.add_child(row)
	modal_button("返回旅程",close_modal)

func _exit_tree() -> void:
	preload("res://scripts/pixel_art.gd").texture_cache.clear()
	WorldArt.cache.clear()

func is_land(point: Vector2i) -> bool:
	if point.x < 1 or point.x > 16 or point.y < 1 or point.y > 9: return false
	if point.y == 1 and (point.x < 3 or point.x > 14): return false
	if point.y == 2 and point.x == 1: return false
	if point.y == 9 and (point.x < 2 or point.x > 15): return false
	if area == 2 and point.y == 1 and point.x in [3,14]: return false
	return true

func reset_visual_positions() -> void:
	visual_player = Vector2(player)
	var behind := player+Vector2i(0,1)
	if not is_land(behind) or behind in obstacle_tiles() or behind in [Vector2i(2,5),Vector2i(3,4)]: behind = player+Vector2i(0,-1)
	if not is_land(behind) or behind in obstacle_tiles() or behind in [Vector2i(2,5),Vector2i(3,4)]: behind = player
	companion_target = Vector2(behind)
	companion_visual = companion_target

func local_dex_count(island: int) -> int:
	var count := 0
	for id in known:
		if int(SPECIES[id].island) == island: count += 1
	return count

func talk_keeper() -> void:
	if mode != "explore" or (player.distance_to(Vector2i(2,5)) > 2 and player.distance_to(Vector2i(3,4)) > 1):
		message = "阿岚在西侧营地附近等你。靠近后按 R，或选择交谈。"
		refresh()
		return
	var speech := ["先认识你的伙伴，再去赛场。你父母留下的每条记录都有用，但你不需要独自承担所有事情。","图鉴里的栖息记录和运输编号对不上。完成赤岩资格，我们就能调阅下一段记录。","最后一枚资格在这里。取得许可后先去研究站，等家人平安了，再完成你的冠军梦想。"]
	story_flags["keeper_met_%d" % zone] = true
	save_game(false)
	var context := "\n\n"+str(Story.objective(self).step)
	if completed[zone]: context += "\n阿岚：你的地区资格已经登记。按 J 查看下一阶段；图鉴调查不会阻止救援主线。"
	elif fragments >= 3: context += "\n阿岚：注意导师的蓄力提示，用防御保护伙伴。训练师对手不能捕捉。"
	open_modal("阿岚 · 营地研究员", speech[zone]+context)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/art/aran_portrait.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(620,180)
	modal_body.add_child(portrait)
	for topic in ["research","league","gentle"]:
		modal_button(str(Story.KEEPER_TOPICS[topic].title),show_keeper_topic.bind(topic))
	modal_button("下一步该去哪里？",show_quest_journal)
	modal_button("查看本地区生态委托",show_keeper_quest)
	modal_button("寻找尚未记录的同伴",keeper_hint)
	modal_button("返回旅程",close_modal)

func show_keeper_quest() -> void:
	var count := local_dex_count(zone)
	open_modal("生态手记 · "+str(ISLANDS[zone].name), "阿岚请你记录至少六种本地区灵兽。\n"+"当前记录：%d / 6\n奖励：六张捕捉胶囊、全队恢复，以及永久 +2%% 捕捉成功率。\n每个地区可完成一次。" % count)
	modal_button("委托已完成" if keeper_rewards[zone] else "领取观察奖励",claim_keeper_reward)
	modal_body.get_child(modal_body.get_child_count()-1).disabled = bool(keeper_rewards[zone]) or count < 6
	modal_button("请阿岚提供线索",keeper_hint)
	modal_button("返回营地交谈",talk_keeper)

func claim_keeper_reward() -> void:
	if keeper_rewards[zone] or local_dex_count(zone) < 6: return
	keeper_rewards[zone] = true
	seals += 6
	heal_party()
	message = "完成生态手记！获得六张捕捉胶囊，捕捉成功率永久 +2%。"
	audio.sfx("win")
	save_game(false)
	refresh()
	show_keeper_quest()

func keeper_hint() -> void:
	var missing: Array = []
	for id in range(PET_COUNT):
		if int(SPECIES[id].island) == zone and not known.has(id): missing.append(id)
	if missing.is_empty():
		open_modal("每个名字都有回声", "你已经记录了本地区所有 36 种灵兽。阿岚笑着把这段故事写进了研究日志。")
	else:
		var id: int = missing[rng.randi_range(0,missing.size()-1)]
		var species: Dictionary = SPECIES[id]
		open_modal("研究员提供的线索", "试着去 %s，在%s寻找 %s。\n\n%s" % [AREAS[zone][int(species.area)],"任意时间",species.name,species.lore])
	modal_button("返回交谈",talk_keeper)
	modal_button("出发寻找",close_modal)

func capture_chance() -> float:
	if guardian_battle or enemy.is_empty(): return 0
	return minf(0.95,0.2+0.7*(1.0-float(enemy.hp)/float(enemy.max_hp))+relics.count(true)*0.005+keeper_rewards.count(true)*0.02)

# Backpack shares existing creature dictionaries and the version-2 save format.
func backpack_at_camp() -> bool:
	return mode == "explore" and area == 0 and player.distance_to(Vector2i(2,5)) <= 1

func show_backpack(storage: bool = false, page: int = 0) -> void:
	if mode != "explore": return
	var pets: Array = reserve if storage else party
	page = clampi(page,0,maxi(0,int((pets.size()-1)/6)))
	open_modal("宠物背包", "随行 %d / 6 · 后备 %d / 200 · 捕捉胶囊 %d\n随时查看与选择出战；营地可存取，须保留一名可战斗同伴。" % [party.size(),reserve.size(),seals])
	var panel: PanelContainer = modal.get_child(1)
	panel.position.y = 20
	panel.size.y = 680
	var tabs := HBoxContainer.new()
	for tab in [false,true]:
		var button := Button.new()
		button.text = ("随行队伍" if not tab else "后备宠物") + (" · 当前" if tab == storage else "")
		button.custom_minimum_size = Vector2(300,36)
		button.pressed.connect(show_backpack.bind(tab,0))
		tabs.add_child(button)
	modal_body.add_child(tabs)
	var grid := GridContainer.new()
	grid.name = "BackpackGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	for i in range(page*6,mini(pets.size(),page*6+6)):
		var p: Dictionary = pets[i]
		var species: Dictionary = SPECIES[int(p.species)]
		var card := Button.new()
		card.custom_minimum_size = Vector2(208,154)
		card.pressed.connect(show_backpack_pet.bind(storage,i))
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 8
		content.offset_right = -8
		content.offset_top = 6
		content.offset_bottom = -6
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = preload("res://scripts/pixel_art.gd").portrait(int(p.species))
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(portrait)
		var label := Label.new()
		label.text = "%s  Lv.%d%s\n生命 %d / %d" % [species.name,p.level," · 出战" if not storage and i == active else "",p.hp,p.max_hp]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		var hp := ProgressBar.new()
		hp.max_value = p.max_hp
		hp.value = p.hp
		hp.show_percentage = false
		hp.custom_minimum_size.y = 8
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(hp)
		grid.add_child(card)
	modal_body.add_child(grid)
	if pets.is_empty():
		var empty := Label.new()
		empty.text = "后备箱暂无宠物。队伍满员后，新同伴会进入这里。"
		modal_body.add_child(empty)
	var nav := HBoxContainer.new()
	for direction in [-1,1]:
		var button := Button.new()
		button.text = "上一页" if direction < 0 else "下一页"
		button.custom_minimum_size = Vector2(160,34)
		button.disabled = page == 0 if direction < 0 else (page+1)*6 >= pets.size()
		button.pressed.connect(show_backpack.bind(storage,page+direction))
		nav.add_child(button)
	var count := Label.new()
	count.text = "第 %d / %d 页" % [page+1,maxi(1,int(ceil(pets.size()/6.0)))]
	nav.add_child(count)
	modal_body.add_child(nav)
	modal_button("返回旅程",close_modal)
	if grid.get_child_count() > 0: grid.get_child(0).grab_focus()

func show_backpack_pet(storage: bool, index: int) -> void:
	if mode != "explore": return
	var pets: Array = reserve if storage else party
	if index < 0 or index >= pets.size(): return
	var p: Dictionary = pets[index]
	var species: Dictionary = SPECIES[int(p.species)]
	open_modal(str(species.name), "Lv.%d · [%s] · 生命 %d / %d · 经验 %d / 3\n技能：%s\n%s" % [p.level,Elements.names(species.elements),p.hp,p.max_hp,p.xp,Moves.catalogue(species),species.lore])
	var panel: PanelContainer = modal.get_child(1)
	panel.position.y = 20
	panel.size.y = 680
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = preload("res://scripts/pixel_art.gd").portrait(int(p.species))
	image.custom_minimum_size.y = 130
	modal_body.add_child(image)
	if not storage:
		modal_button("当前出战" if index == active else "设为出战伙伴",backpack_select.bind(index))
		modal_body.get_child(modal_body.get_child_count()-1).disabled = index == active or int(p.hp) <= 0
	if backpack_at_camp():
		modal_button(("取出到队伍" if party.size() < 6 else "与出战伙伴交换") if storage else "存入后备箱",backpack_transfer.bind(storage,index))
		var blocked := false
		if storage:
			blocked = party.size() == 6 and int(p.hp) <= 0 and int(party[active].hp) > 0 and party.filter(func(pet): return int(pet.hp) > 0).size() <= 1
		else:
			blocked = party.size() <= 1 or reserve.size() >= 200 or (int(p.hp) > 0 and party.filter(func(pet): return int(pet.hp) > 0).size() <= 1)
		modal_body.get_child(modal_body.get_child_count()-1).disabled = blocked
	else:
		var hint := Label.new()
		hint.text = "返回营地可调整队伍与后备；存入时须保留一名可战斗同伴。"
		hint.add_theme_font_size_override("font_size",16)
		modal_body.add_child(hint)
	modal_button("返回宠物背包",show_backpack.bind(storage,int(index/6)))

func backpack_select(index: int) -> void:
	if mode != "explore" or index < 0 or index >= party.size() or int(party[index].hp) <= 0: return
	switch_to(index)
	save_game(false)
	show_backpack()

func backpack_transfer(storage: bool, index: int) -> void:
	if not backpack_at_camp(): return
	if storage:
		if index < 0 or index >= reserve.size(): return
		if party.size() < 6: party.append(reserve.pop_at(index))
		else:
			# Never exchange away the last conscious companion for a fainted one.
			if int(reserve[index].hp) <= 0 and party.filter(func(p): return int(p.hp) > 0).size() <= 1 and int(party[active].hp) > 0: return
			var old: Dictionary = party[active]
			party[active] = reserve[index]
			reserve[index] = old
	else:
		if index < 0 or index >= party.size() or party.size() <= 1 or reserve.size() >= 200: return
		if int(party[index].hp) > 0 and party.filter(func(p): return int(p.hp) > 0).size() <= 1: return
		reserve.append(party.pop_at(index))
		if index < active: active -= 1
		elif index == active: active = 0
	if int(party[active].hp) <= 0:
		for i in range(party.size()):
			if int(party[i].hp) > 0:
				active = i
				break
	save_game(false)
	refresh()
	show_backpack(storage)

func show_elements() -> void:
	open_modal("十二属性 · 克制手册", "宠物最多两种属性，招式各有一种属性。\n克制 ×1.5，双弱点最高 ×2，其余 ×1；不自动产生抵抗。\n光暗互克、龙克自身。没有环境增伤或切换门槛。")
	for element in range(TYPES.size()):
		var text := Label.new()
		text.text = "%s · 克制：%s · 被克制：%s\n%s" % [TYPES[element],Elements.names(Elements.STRONG[element]),Elements.names(Elements.weaknesses(element)),Elements.REASONS[element]]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		modal_body.add_child(text)
	modal_button("返回旅程",close_modal)

func observe_region() -> void:
	story_flags["visited_%d_%d" % [zone,area]] = true

func field_npc_position() -> Vector2i:
	return Vector2i(3,6) if area == 1 else Vector2i(7,4)

func interact_nearby() -> void:
	if mode != "explore": return
	if area > 0 and player.distance_to(field_npc_position()) <= 1:
		talk_field_npc()
	elif player.distance_to(Vector2i(15,2)) <= 1:
		show_arena_desk()
	else: talk_keeper()

func region_dex_count() -> int:
	var count := 0
	for id in known:
		if int(SPECIES[id].island) == zone and int(SPECIES[id].area) == area: count += 1
	return count

func talk_field_npc() -> void:
	if mode != "explore" or area == 0 or player.distance_to(field_npc_position()) > 1: return
	var done := bool(story_flags.get("field_reward_%d_%d" % [zone,area],false))
	var title := "茵禾 · 生态观测员" if area == 1 else "乔渡 · 驿道巡查员"
	var speech := "图鉴的价值不在页数，而在记录是否真实。帮我登记本区域四种不同伙伴，我们就能核对运输记录。" if area == 1 else "运输清单被涂改过。有人只留下了一道安全考题：调查员应如何进入研究站？我想先听听你的判断。"
	if done: speech = "这份调查已经归档，谢谢你。"+("伙伴的真实栖息记录会交给调查办公室。" if area == 1 else "前往研究站之前，记得准备不同属性的队伍。")
	open_modal(title,speech+"\n\n"+str(Story.REGIONS[zone][area]))
	enlarge_story_modal()
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = load("res://assets/art/yinhe_portrait.png" if area == 1 else "res://assets/art/qiaodu_portrait.png")
	portrait.custom_minimum_size.y = 180
	modal_body.add_child(portrait)
	if area == 1:
		modal_button("提交区域记录（%d / 4）" % region_dex_count(),claim_field_reward)
		modal_body.get_child(modal_body.get_child_count()-1).disabled = done or region_dex_count() < 4
	else:
		modal_button("回答巡查问题",show_patrol_question)
		modal_body.get_child(modal_body.get_child_count()-1).disabled = done
	modal_button("关于父母的线索",show_field_rumor)
	modal_button("查看主线与委托",show_quest_journal)
	modal_button("返回探索",close_modal)

func show_field_rumor() -> void:
	if mode != "explore" or area == 0: return
	var text := ["你母亲在运输车离开前，给每个箱子补上了真正的栖息地。青芽记录里藏着第一段校验码。","赤岩的货运编号被重复使用。你父亲留下的校验码，能证明同一批伙伴被转移了两次。","研究站的样本保全室仍有人值守。三地资格齐全后，调查办公室会允许你进入封锁区。"]
	if story_flags.get("parents_rescued",false): text[zone] = "你的父母已经由调查员送回安全地点。研究站的伙伴正在分批回到原栖息地。现在你可以安心准备冠军赛了。"
	story_flags["rumor_%d_%d" % [zone,area]] = true
	save_game(false)
	open_modal("调查线索",text[zone])
	modal_button("返回交谈",talk_field_npc)

func show_patrol_question() -> void:
	if mode != "explore" or area != 2 or player.distance_to(field_npc_position()) > 1: return
	var questions := ["遇见不熟悉的野外伙伴，应该先做什么？", "发现两个地区的运输记录重复，什么证据最可靠？", "研究站可能有未知对手，调查员应如何准备？"]
	var answers := ["观察习性、保持距离，确认安全再靠近", "核对图鉴栖息地和原始登记编号", "带不同属性的伙伴，检查补给，再按许可进入"]
	var wrong := ["不观察，直接强行捕捉", "只看数量，不核对来源", "不做准备，直接闯入"]
	open_modal("乔渡的巡查问题",questions[zone])
	modal_button(answers[zone],claim_field_reward)
	modal_button(wrong[zone],patrol_wrong_answer)
	modal_button("先回去整理队伍",close_modal)

func patrol_wrong_answer() -> void:
	open_modal("乔渡 · 再想一想", "冲动可能让伙伴受伤。你随时可以回营地恢复、查看属性手册，再回来回答。答错不会扣除物品。")
	modal_button("重新回答",show_patrol_question)
	modal_button("返回探索",close_modal)

func claim_field_reward() -> void:
	if mode != "explore" or area == 0 or player.distance_to(field_npc_position()) > 1: return
	var key := "field_reward_%d_%d" % [zone,area]
	if story_flags.get(key,false) or (area == 1 and region_dex_count() < 4): return
	story_flags[key] = true
	seals += 3
	message = "调查委托完成！获得 3 枚捕捉胶囊。奖励仅可领取一次。"
	audio.sfx("win")
	save_game(false)
	refresh()
	talk_field_npc()

func show_keeper_topic(topic: String) -> void:
	if mode != "explore" or not Story.KEEPER_TOPICS.has(topic): return
	story_flags["topic_"+topic] = true
	save_game(false)
	var entry: Dictionary = Story.KEEPER_TOPICS[topic]
	open_modal(str(entry.title),str(entry.text))
	modal_button("返回阿岚交谈",talk_keeper)
	modal_button("查看当前主线",show_quest_journal)

func show_quest_journal() -> void:
	if mode != "explore": return
	var objective: Dictionary = Story.objective(self)
	open_modal("训练师日志",str(objective.title)+"\n"+str(objective.step)+"\n"+str(objective.progress)+"\n\n"+str(Story.REGIONS[zone][area]))
	enlarge_story_modal()
	modal_button("追踪主线目标",set_tracking.bind("main"))
	if int(objective.zone) != zone or int(objective.area) != area:
		modal_button("前往主线区域 · "+str(AREAS[int(objective.zone)][int(objective.area)]),visit_region.bind(int(objective.zone),int(objective.area)))
	modal_button("追踪营地 / 阿岚",set_tracking.bind("camp"))
	if area > 0: modal_button("追踪本区 NPC",set_tracking.bind("field"))
	var tasks := Label.new()
	tasks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tasks.text = "可选调查：\n阿岚 · 本地区六种记录：%d / 6%s\n茵禾 · 林区四种记录%s\n乔渡 · 巡查问答%s\n\n这些委托不阻止主线，奖励可辅助补给。" % [mini(6,local_dex_count(zone)),"（已交付）" if keeper_rewards[zone] else "", "（已交付）" if story_flags.get("field_reward_%d_1" % zone,false) else "", "（已交付）" if story_flags.get("field_reward_%d_2" % zone,false) else ""]
	modal_body.add_child(tasks)
	for chapter in range(3):
		if chapter == 0 or completed[chapter-1]: modal_button("回顾 · "+str(Story.CHAPTERS[chapter].title),replay_chapter.bind(chapter))
	if story_flags.get("parents_rescued",false): modal_button("回顾 · 父母救援",show_story.bind(Story.RESCUE_END))
	if story_flags.get("champion",false): modal_button("回顾 · 冠军结局",show_story.bind(Story.CHAMPION_END))
	modal_button("返回探索",close_modal)

func replay_chapter(chapter: int) -> void:
	if chapter < 0 or chapter > 2 or (chapter > 0 and not completed[chapter-1]): return
	open_modal(str(Story.CHAPTERS[chapter].title),str(Story.CHAPTERS[chapter].intro)+("\n\n"+str(Story.CHAPTERS[chapter].ending) if completed[chapter] else ""))
	modal_button("返回日志",show_quest_journal)

func set_tracking(goal: String) -> void:
	if goal not in ["main","camp","field"]: return
	tracked_goal = goal
	save_game(false)
	close_modal()
	refresh()

func update_guide() -> void:
	guide_path.clear()
	var objective: Dictionary = Story.objective(self)
	var goal: String = str(objective.goal) if tracked_goal == "main" else tracked_goal
	var target := Vector2i(15,2) if goal == "arena" else Vector2i(2,6)
	if tracked_goal == "main" and (int(objective.zone) != zone or int(objective.area) != area):
		goal = "camp"
		target = Vector2i(2,6)
	elif goal == "field" and area > 0: target = field_npc_position()+Vector2i.RIGHT
	var queue: Array[Vector2i] = [player]
	var previous: Dictionary = {player:player}
	var found := false
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if (goal == "grass" and is_grass(current)) or (goal != "grass" and current == target):
			target = current
			found = true
			break
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = current+delta
			if previous.has(next) or not is_land(next) or next in obstacle_tiles() or next in [Vector2i(2,5),Vector2i(3,4)]: continue
			previous[next] = current
			queue.append(next)
	if not found: return
	while target != player:
		guide_path.push_front(target)
		target = previous[target]

func show_local_map() -> void:
	if mode != "explore": return
	update_guide()
	var objective: Dictionary = Story.objective(self)
	open_modal("本区地图 · "+str(AREAS[zone][area]),str(Story.REGIONS[zone][area])+"\n当前主线："+str(objective.step))
	enlarge_story_modal()
	var chart := preload("res://scripts/local_chart.gd").new()
	chart.game = self
	chart.custom_minimum_size = Vector2(660,275)
	modal_body.add_child(chart)
	modal_button("查看世界地图 / 切换地区",show_world_map)
	modal_button("查看任务日志",show_quest_journal)
	modal_button("返回探索",close_modal)

func start_special_battle(kind: String) -> void:
	if mode != "explore" or completed.count(true) < 3 or zone != 2 or player != Vector2i(15,2): return
	if kind == "rescue":
		if area != 2 or story_flags.get("parents_rescued",false): return
	elif kind == "championship":
		if area != 0 or not story_flags.get("parents_rescued",false) or story_flags.get("champion",false): return
	else: return
	start_battle(13 if kind == "rescue" else 68,true)
	special_battle_kind = kind
	opponent_roster = [creature(13,8),creature(91,8)] if kind == "rescue" else [creature(68,9),creature(8,9),creature(102,9)]
	opponent_slot = 0
	enemy = opponent_roster[0].duplicate(true)
	message = "研究站封锁员发起挑战！击败对方，打开样本保全室。" if kind == "rescue" else "冠军赛开始！许澈派出了最后的搭档。"
	refresh()

func show_arena_desk() -> void:
	if mode != "explore" or player.distance_to(Vector2i(15,2)) > 1: return
	if area != 0 and not (zone == 2 and area == 2 and completed.count(true) == 3):
		open_modal("区域巡查站", "地区资格赛位于%s。这里负责野外调查，不举行导师考核。" % AREAS[zone][0])
		modal_button("返回地区赛场",visit_region.bind(zone,0))
		modal_button("返回探索",close_modal)
		return
	var names := ["春蕾 · 青芽导师","唐砾 · 赤岩导师","凌朔 · 星原导师"]
	var target := int(ISLANDS[zone].boss)
	var heading: String = names[zone]
	var prompt := "资格要求：3 积分。训练师的伙伴不可捕捉。观察蓄力提示，用防御和换宠管理战局。"
	if completed.count(true) == 3 and zone == 2 and area == 2 and not story_flags.get("parents_rescued",false):
		heading = "研究站 · 封锁入口"
		target = 13
		prompt = "父母被困在样本保全室。你的调查许可已经核验；准备好队伍后，进入入口完成救援战。"
	elif story_flags.get("parents_rescued",false) and zone == 2 and area == 0:
		heading = "许澈 · 冠军赛"
		target = 68
		prompt = "许澈：你先把家人带回来了。接下来，完成你和伙伴自己的梦想吧。"
	open_modal(heading,prompt+"\n\n对方搭档："+str(SPECIES[target].name)+" ["+Elements.names(SPECIES[target].elements)+"]")
	modal_button("进入赛场 / 研究站入口",enter_arena)
	modal_button("查看属性手册",show_elements)
	modal_button("返回整理队伍",close_modal)

func enter_arena() -> void:
	if mode != "explore" or player.distance_to(Vector2i(15,2)) > 1: return
	close_modal()
	player = Vector2i(15,2)
	if completed.count(true) == 3 and zone == 2 and area == 2 and not story_flags.get("parents_rescued",false): start_special_battle("rescue")
	elif zone == 2 and area == 0 and story_flags.get("parents_rescued",false) and not story_flags.get("champion",false): start_special_battle("championship")
	elif area == 0 and not completed[zone] and fragments >= 3: start_battle(int(ISLANDS[zone].boss),true)
	else:
		message = "当前没有可开始的挑战。按 J 查看资格要求或下一阶段。"
		refresh()

func enlarge_story_modal() -> void:
	var panel: PanelContainer = modal.get_child(1)
	panel.position.y = 20
	panel.size.y = 680

func show_battle_party() -> void:
	if mode != "battle" or busy: return
	open_modal("选择出战伙伴", "换宠会消耗一个回合，对方会行动。取消不会消耗回合。\n本场能量和药草不会重置，倒下的伙伴不可出战。")
	for index in range(party.size()):
		var companion: Dictionary = party[index]
		var species: Dictionary = SPECIES[int(companion.species)]
		modal_button("换上 %s · Lv.%d · 生命 %d/%d · [%s]%s" % [species.name,companion.level,companion.hp,companion.max_hp,Elements.names(species.elements)," · 当前" if index == active else ""],select_battle_party.bind(index))
		modal_body.get_child(modal_body.get_child_count()-1).disabled = index == active or int(companion.hp) <= 0
	modal_button("取消 / 返回战斗",close_modal)

func select_battle_party(index: int) -> void:
	if mode != "battle" or busy or index < 0 or index >= party.size() or index == active or int(party[index].hp) <= 0: return
	close_modal()
	switch_to(index)
