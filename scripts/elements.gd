extends RefCounted
# Stable indices preserve legacy wood/fire/water IDs. No implicit resistance.
const NAMES = ["木","火","水","金","土","风","雷","光","暗","冰","龙","虫"]
const STRONG = [[2,4],[3,0,9,11],[1,11],[0,9,4,10],[2,1,6],[4,11],[2,3,5],[8],[7],[0,2,5],[10],[0]]
const REASONS = ["植物吸水；根系破土。","高温熔金、焚木、融冰、灼伤虫体。","水流灭火，冲散虫群。","金刃斩木、碎冰、开凿岩土、穿透龙鳞。","堤坝挡水，沙土灭火，大地消散雷电。","风蚀土层，强风吹散虫群。","雷电借水和金属传导，雷击威胁空中目标。","光照驱散暗影。","暗域吞噬光芒。","冻结植物与水流，冰霜压制风系机动。","龙息穿透同族防护。","啃食草木，蛀蚀树干。"]

static func single(attack: int, defense: int) -> float:
	if attack < 0 or attack >= NAMES.size() or defense < 0 or defense >= NAMES.size(): return 1.0
	return 1.5 if STRONG[attack].has(defense) else 1.0

static func multiplier(attack: int, defenses: Array) -> float:
	var result := 1.0
	var seen: Array = []
	for element in defenses:
		if seen.has(int(element)): continue
		seen.append(int(element))
		result *= single(attack,int(element))
	return minf(2.0,result)

static func names(elements: Array) -> String:
	var labels: Array[String] = []
	for element in elements: labels.append(NAMES[int(element)])
	return " / ".join(labels)

static func weaknesses(element: int) -> Array:
	var result: Array = []
	for attack in range(NAMES.size()):
		if STRONG[attack].has(element): result.append(attack)
	return result

static func hint(value: float) -> String:
	return ("克制" if value > 1.0 else "中性")+" ×%.2f" % value
