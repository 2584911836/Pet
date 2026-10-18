extends RefCounted
# All species reference explicit, inspectable skill profiles in game_data.gd.
const KINDS = ["leech","burn","shield","regen","break","echo","focus","surge","execute","mark","poison"]
const PASSIVES = ["共鸣技恢复 4 生命", "生命低于一半时伤害 +25%", "防御时恢复 4 生命", "共鸣技恢复 8 生命", "受到的伤害减少 2", "药草回复提高至 30", "对高生命目标的共鸣技 +20%", "普通攻击恢复 2 点能量", "共鸣技同时抵御下一次攻击"]

static func state() -> Dictionary:
	return {"shield":0,"dot":0,"dot_turns":0,"regen":0,"regen_turns":0,"broken":0,"mark":0,"echo":0}

static func description(s: Dictionary) -> String:
	var n := int(s.skill_value)
	var effect := ""
	match str(s.skill_kind):
		"leech": effect = "命中恢复自身 %d 生命" % n
		"burn": effect = "施加余烬：接下来 2 次反击前各损失 %d 生命（不叠加）" % n
		"poison": effect = "施加缓蚀：接下来 3 次反击前各损失 %d 生命（不叠加）" % maxi(1,n-2)
		"shield": effect = "获得 %d 护盾，吸收后续直接伤害（刷新、不叠加）" % (n*2)
		"regen": effect = "获得润泽：本次及下次反击前各恢复 %d 生命" % n
		"break": effect = "破甲：接下来受到的 2 次直接攻击各增加 %d 伤害" % n
		"echo": effect = "蓄积回响：下一次直接攻击增加 %d 伤害" % (n*2)
		"focus": effect = "命中返还 1 点能量，额外恢复 %d 生命" % n
		"surge": effect = "自身生命不高于一半时额外造成 %d 伤害，否则获得 %d 护盾" % [n*2,n*2]
		"execute": effect = "目标生命不高于一半时，额外造成 %d 伤害" % (n*3)
		"mark": effect = "标记目标：下一次直接攻击增加 %d 伤害" % (n*2)
	return "伤害系数 %.2f · 消耗 2 能量\n%s" % [float(s.skill_scale),effect]

static func apply(s: Dictionary, user: Dictionary, own: Dictionary, target: Dictionary, charged: bool) -> void:
	var n := int(s.skill_value)
	match str(s.skill_kind):
		"leech", "focus": user.hp = mini(int(user.max_hp),int(user.hp)+n)
		"burn", "poison":
			target.dot = n if s.skill_kind == "burn" else maxi(1,n-2)
			target.dot_turns = 2 if s.skill_kind == "burn" else 3
		"shield": own.shield = maxi(int(own.shield),n*2)
		"regen":
			own.regen = n
			own.regen_turns = 2
		"break":
			target.broken = 2
			target["break_value"] = n
		"echo": own.echo = n*2
		"mark": target.mark = n*2
		"surge":
			if not charged: own.shield = maxi(int(own.shield),n*2)

static func bonus(s: Dictionary, target: Dictionary, charged: bool) -> int:
	if s.skill_kind == "surge" and charged: return int(s.skill_value)*2
	if s.skill_kind == "execute" and int(target.hp)*2 <= int(target.max_hp): return int(s.skill_value)*3
	return 0

static func direct_damage(amount: int, own: Dictionary, target: Dictionary) -> int:
	amount += int(own.echo)+int(target.mark)
	own.echo = 0
	target.mark = 0
	if int(target.broken) > 0:
		amount += int(target.get("break_value",0))
		target.broken -= 1
	var absorbed := mini(int(target.shield),amount)
	target.shield -= absorbed
	return maxi(0,amount-absorbed)

static func tick(pet: Dictionary, status: Dictionary) -> Dictionary:
	var before := int(pet.hp)
	if int(pet.hp) <= 0: return {"damage":0,"healing":0}
	if int(status.dot_turns) > 0:
		pet.hp = maxi(0,int(pet.hp)-int(status.dot))
		status.dot_turns -= 1
	var hurt := before-int(pet.hp)
	before = int(pet.hp)
	if int(pet.hp) > 0 and int(status.regen_turns) > 0:
		pet.hp = mini(int(pet.max_hp),int(pet.hp)+int(status.regen))
		status.regen_turns -= 1
	return {"damage":hurt,"healing":int(pet.hp)-before}

static func status_text(status: Dictionary) -> String:
	var tags: Array[String] = []
	if int(status.shield) > 0: tags.append("盾%d" % status.shield)
	if int(status.dot_turns) > 0: tags.append("侵蚀%d×%d" % [status.dot,status.dot_turns])
	if int(status.regen_turns) > 0: tags.append("润泽%d×%d" % [status.regen,status.regen_turns])
	if int(status.broken) > 0: tags.append("破甲%d回" % status.broken)
	if int(status.mark) > 0: tags.append("标记+%d" % status.mark)
	if int(status.echo) > 0: tags.append("回响+%d" % status.echo)
	return " · ".join(tags)
