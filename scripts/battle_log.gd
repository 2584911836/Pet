extends RefCounted
const Growth = preload("res://scripts/progression.gd")
var opening: Array = []
var participants: Array[int] = []
var label := "野外遭遇"
var opponents: Array = []
var actions := 0
var capsules := 0
var herbs := 0
var rewarded := false
var settled := false

func begin(party: Array, active: int, title: String, opponent: int) -> void:
	opening = party.duplicate(true)
	participants = [active]
	label = title
	opponents = [opponent]
	actions = 0
	capsules = 0
	herbs = 0
	rewarded = false
	settled = false

func register(index: int) -> void:
	if not settled and index >= 0 and index < opening.size() and index not in participants: participants.append(index)

func action(kind: String) -> void:
	if settled: return
	actions += 1
	if kind == "capture": capsules += 1
	elif kind == "heal": herbs += 1

func grant(party: Array) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	if rewarded or settled: return messages
	rewarded = true
	for index in participants:
		if index >= party.size(): continue
		var pet: Dictionary = party[index]
		var levels := Growth.gain(pet,1)
		if levels > 0: messages.append({"species":int(pet.species),"level":int(pet.level),"levels":levels})
	return messages

func finish(party: Array, outcome: String, points: int = 0, guidance: bool = false, captured: int = -1) -> Dictionary:
	settled = true
	var rows := []
	for index in range(mini(opening.size(),party.size())):
		var before: Dictionary = opening[index]
		var after: Dictionary = party[index]
		if index not in participants and not guidance: continue
		rows.append({"species":int(after.species),"before_level":int(before.level),"level":int(after.level),"before_xp":int(before.xp),"xp":int(after.xp),"max_hp":int(after.max_hp),"participated":index in participants,"earned":1 if rewarded and index in participants and int(before.level) < Growth.MAX_LEVEL else 0,"guidance":guidance and int(before.level) < Growth.MAX_LEVEL})
	return {"label":label,"outcome":outcome,"actions":actions,"capsules":capsules,"herbs":herbs,"points":points,"captured":captured,"opponents":opponents.duplicate(),"rows":rows}
