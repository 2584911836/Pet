extends RefCounted

const SPECIES = [
	{"name":"苔芽兽", "type":0, "color":Color("83d68a"), "max_hp":44, "power":10, "skill":"枝叶回响", "lore":"把晨露藏在头顶的嫩芽里。愿意与安静的旅人同行。"},
	{"name":"烬尾狐", "type":1, "color":Color("f6ac72"), "max_hp":38, "power":12, "skill":"星火跃击", "lore":"尾尖的火种从不熄灭，会为迷路者照亮小径。"},
	{"name":"泡鳍灵", "type":2, "color":Color("79c9e9"), "max_hp":48, "power":9, "skill":"回旋水幕", "lore":"听得懂贝壳里的回声，涨潮时在礁石间唱歌。"},
	{"name":"灯蕨鹿", "type":0, "color":Color("c5d98c"), "max_hp":48, "power":11, "skill":"荧蕨穿刺", "lore":"鹿角结出微光孢子，照亮雾中的旧航道。"},
	{"name":"焰盔蟹", "type":1, "color":Color("e28678"), "max_hp":54, "power":9, "skill":"熔壳冲撞", "lore":"用温暖的甲壳孵化海鸟遗落的蛋，脾气却很倔强。"},
	{"name":"雾铃鲸", "type":2, "color":Color("b0addf"), "max_hp":46, "power":12, "skill":"雾海长歌", "lore":"小小的身体装着很远的海，歌声能抚平风浪。"},
	{"name":"冠苔鸮", "type":0, "color":Color("a3cbb2"), "max_hp":42, "power":14, "skill":"翡翠风刃", "lore":"以树叶为冠，把整座岛的秘密记在年轮里。"},
	{"name":"曜羽雀", "type":1, "color":Color("f2ce83"), "max_hp":43, "power":14, "skill":"黎明焰羽", "lore":"第一缕曙光落在哪里，它就会飞向哪里。"},
	{"name":"星潮龙", "type":2, "color":Color("8ab9d6"), "max_hp":58, "power":11, "skill":"星河潮涌", "lore":"古老航图上的最后一颗星，是它留下的鳞光。"}
]
const ISLANDS = [
	{"name":"微光岛", "subtitle":"第一章 · 风中的约定", "ground":Color("a6b18a"), "grass":Color("427563"), "water":Color("28536b"), "boss":2, "level":3,
	"intro":"守灯人留下了一枚潮铃。摇动它，海水便会回应。点亮三座灯塔，让失散的群岛重新相连。",
	"ending":"第一束灯光穿过海雾。远处传来一声鲸鸣——下一座岛正在回应你。"},
	{"name":"雾钟湾", "subtitle":"第二章 · 遗落的航歌", "ground":Color("a6a5b6"), "grass":Color("566985"), "water":Color("344769"), "boss":4, "level":5,
	"intro":"雾钟湾的航歌沉在海底。低潮显露出旧石桥，高潮时，另一群灵兽循着歌声归来。",
	"ending":"第二座灯塔点亮，旧航歌再次响起。灯蕨与火羽在海上铺出通向星落屿的路。"},
	{"name":"星落屿", "subtitle":"第三章 · 海的另一端", "ground":Color("b4a68b"), "grass":Color("526e70"), "water":Color("263e58"), "boss":8, "level":7,
	"intro":"星落屿的灯塔已经沉寂很久。最后的守卫仍在等待：你带来的，是征服，还是约定？",
	"ending":"三座灯塔的光连成一条星河。灵兽们不再畏惧漫长的海夜。你把潮铃挂回灯塔，却听见了新的回声。\n\n《潮汐灵约》· 全篇完\n感谢你成为群岛的第一位守灯人。可继续探索并完成九种灵兽图鉴。"}
]
