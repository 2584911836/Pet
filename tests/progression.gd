extends SceneTree
const Growth = preload("res://scripts/progression.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL GROWTH: "+label)
func _initialize() -> void:
	var pet := {"level":1,"xp":0,"hp":1,"max_hp":40}
	check(Growth.gain(pet,2) == 0 and pet.xp == 2,"partial XP accumulates")
	check(Growth.gain(pet,1) == 1 and pet.level == 2 and pet.max_hp == 46 and pet.hp == 46,"level up increases health and recovers")
	check(Growth.required(1) == 3 and Growth.required(6) == 4 and Growth.required(99) == 20,"staged experience curve")
	check(Growth.gain(pet,-1) == 0 and pet.xp == 0,"invalid reward cannot remove XP")
	var levels := Growth.gain(pet,10000)
	check(levels == 97 and pet.level == 99 and pet.xp == 0 and pet.max_hp == 628,"bulk reward respects cap and every health increment")
	check(Growth.gain(pet,100) == 0 and pet.xp == 0,"capped pets stop accumulating XP")
	check(Growth.summary(pet,12).contains("上限"),"cap shown clearly")
	print("Growth: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
