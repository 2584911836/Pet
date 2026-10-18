extends RefCounted
const Elements = preload("res://scripts/elements.gd")
const BASIC = ["藤鞭","火花","水弹","钢刃","落石","风刃","电弧","光束","暗袭","冰刺","龙爪","虫咬"]
const COVER = ["根须穿刺","焰流","涌浪","碎甲斩","岩崩","回旋气刃","奔雷","耀光","影蚀","霜裂","龙息","群袭"]

static func list(s: Dictionary) -> Array:
	return [
		{"name":BASIC[int(s.elements[0])],"element":int(s.elements[0]),"cost":0,"scale":1.0,"signature":false},
		{"name":COVER[int(s.coverage)],"element":int(s.coverage),"cost":1,"scale":1.15,"signature":false},
		{"name":str(s.skill),"element":int(s.skill_element),"cost":2,"scale":1.2*float(s.skill_scale),"signature":true}
	]

static func description(move: Dictionary, s: Dictionary) -> String:
	var text := "[%s] · 潮息 %d · 伤害系数 %.2f" % [Elements.NAMES[int(move.element)],move.cost,move.scale]
	if int(move.cost) == 0: text += "\n命中恢复 1 潮息（被动可提高）"
	if bool(move.signature): text += "\n"+preload("res://scripts/signature_skills.gd").description(s).get_slice("\n",1)
	return text

static func catalogue(s: Dictionary) -> String:
	var rows: Array[String] = []
	for move in list(s): rows.append(str(move.name)+" "+description(move,s))
	return "\n\n".join(rows)
