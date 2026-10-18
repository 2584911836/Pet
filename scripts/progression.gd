extends RefCounted
# Early levels stay approachable; later growth requires sustained training.
const MAX_LEVEL := 99
static func required(level: int) -> int:
	return mini(20,3+maxi(0,level-1)/5)

static func gain(pet: Dictionary, amount: int) -> int:
	if amount <= 0 or int(pet.level) >= MAX_LEVEL:
		if int(pet.level) >= MAX_LEVEL: pet.xp = 0
		return 0
	pet.xp = int(pet.xp)+amount
	var levels := 0
	while int(pet.level) < MAX_LEVEL and int(pet.xp) >= required(int(pet.level)):
		pet.xp -= required(int(pet.level))
		pet.level += 1
		pet.max_hp += 6
		pet.hp = pet.max_hp
		levels += 1
	if int(pet.level) >= MAX_LEVEL: pet.xp = 0
	return levels

static func summary(pet: Dictionary, base_power: int) -> String:
	var level := int(pet.level)
	var experience := "已达等级上限" if level >= MAX_LEVEL else "训练经验 %d / %d（再获 %d 点升级）" % [pet.xp,required(level),required(level)-int(pet.xp)]
	return "Lv.%d / %d · %s\n最大生命 %d · 基础战力 %d\n%s" % [level,MAX_LEVEL,experience,pet.max_hp,base_power+level*2,"下一级：生命上限 +6、基础战力 +2，升级恢复生命。" if level < MAX_LEVEL else "已完成等级成长，继续通过属性和技能搭配提升队伍表现。"]
