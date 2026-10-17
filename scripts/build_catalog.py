#!/usr/bin/env python3
"""Rebuild the original 108-species design catalogue. Not needed at runtime."""
from pathlib import Path
import colorsys,csv,json,re
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'scripts/game_data.gd'
old=path.read_text()
islands=old[old.index('const ISLANDS = '):]
# Nine body families; each subsequent ecological form changes silhouette as well as palette.
NAMES=[
'苔芽兽 烬尾狐 泡鳍灵 灯蕨鹿 焰盔蟹 雾铃鲸 冠苔鸮 曜羽雀 星潮龙',
'露角芽团 赤砂绒狐 珊枝鳍灵 月桂鹿 琥甲蟹 云帆鲸 铃叶鸮 流萤雀 星礁龙',
'蒲尾芽团 烟尾绒狐 银尾鳍灵 藤尾鹿 旗尾蟹 绸尾鲸 彗尾鸮 扇尾雀 卷尾龙',
'羽芽团 纸翼绒狐 帆翼鳍灵 浮翼鹿 翅盔蟹 天翼鲸 镜翼鸮 双帆雀 翼潮龙',
'礁壳芽团 瓷甲绒狐 贝甲鳍灵 石衣鹿 晶盔蟹 礁背鲸 盾羽鸮 甲羽雀 城礁龙',
'冠蕊芽团 霜棘绒狐 星棘鳍灵 珠冠鹿 棘岩蟹 冠浪鲸 晶冠鸮 皇冠雀 棘脊龙',
'高足芽团 踏浪绒狐 长足鳍灵 苇足鹿 步桥蟹 浅滩鲸 哨林鸮 跃岸雀 行沙龙',
'伞蕈芽团 茸帽绒狐 莲帽鳍灵 蘑伞鹿 蕈盔蟹 伞云鲸 蘑冠鸮 蕈羽雀 菌冠龙',
'雾绒芽团 烟纱绒狐 霞纱鳍灵 雾鬃鹿 云绒蟹 帷雾鲸 雾披鸮 流霞雀 烟岚龙',
'月耳芽团 望月绒狐 垂铃鳍灵 月珥鹿 环月蟹 听月鲸 月眉鸮 月翎雀 月角龙',
'环光芽团 星环绒狐 涟环鳍灵 日晕鹿 环晶蟹 光轮鲸 星轮鸮 环日雀 晕潮龙',
'弯月芽团 镰尾绒狐 月弧鳍灵 钩月鹿 弯潮蟹 月牙鲸 月镰鸮 弧翼雀 弯湾龙']
FORM_NAMES=['初生','露角','长尾','帆翼','礁甲','冠棘','苇足','伞冠','云纱','月珥','光环','弯月']
FORM_LORE=[
'与最初的守灯人一同生活，是群岛最常见的伙伴。',
'枝角会凝聚夜露，清晨时为同伴留下淡淡的水痕。',
'用长尾试探潮水的方向，尾端的纹路像一幅小航图。',
'两侧的帆翼能够借助海风滑行，落地时几乎没有声音。',
'坚硬的礁甲是与海潮共同生长的证明，内侧却温暖柔软。',
'每一枚冠棘都记录一季风，遇到旧友时会微微发亮。',
'长足能够稳稳站在浅水里，会在潮间带留下奇妙的脚印。',
'伞状冠盖能挡住细雨，暴风来临时会邀请小生物躲到身边。',
'身边的云纱并非水汽，而是它记得的海风凝成的光。',
'垂落的月珥可以听见潮汐，夜里会轻轻敲出规律的节拍。',
'环绕身体的光轮来自旧灯塔，在最暗的海夜仍然清晰可见。',
'弯月状的附肢会在逆风时展开，帮助它寻找归航的路。']
FAMILY_LORE=['喜欢收集柔软的苔藓。','会把捡到的漂亮石子送给旅人。','把贝壳中的回声当作自己的名字。','只会在信任的人面前低下额头。','会耐心修补被海浪冲坏的小巢。','用低低的歌声回答远方的伙伴。','记得每一位经过林间的旅人。','喜欢在第一缕晨光里练习飞翔。','把群岛上最古老的约定记在鳞片里。']
COLORS=['83d68a','f6ac72','79c9e9','c5d98c','e28678','b0addf','a3cbb2','f2ce83','8ab9d6']
SKILLS=['枝叶回响','星火跃击','回旋水幕','荧蕨穿刺','熔壳冲撞','雾海长歌','翡翠风刃','黎明焰羽','星河潮涌']
BASE_HP=[44,38,48,48,54,46,42,43,58]
BASE_POWER=[10,12,9,11,9,12,14,14,11]
rows=[]
for form,names in enumerate(NAMES):
 for family,name in enumerate(names.split()):
  species_id=form*9+family
  element=(family+form//4)%3
  role=(form+family*2)%6
  hue,sat,val=colorsys.rgb_to_hsv(*(int(COLORS[family][i:i+2],16)/255 for i in (0,2,4)))
  rgb=colorsys.hsv_to_rgb((hue+form*0.017)%1,min(0.58,sat+form*0.007),min(0.95,val))
  color=''.join(f'{round(c*255):02x}' for c in rgb)
  tide=(form+family)%2 if form else (0 if family%3==0 else -1 if family%3==1 else 1)
  rows.append(dict(name=name,type=element,color=color,max_hp=BASE_HP[family] if form==0 else 40+role*4,power=BASE_POWER[family] if form==0 else 15-role,skill=SKILLS[family] if form==0 else FORM_NAMES[form]+['森鸣','焰歌','潮咏'][element],lore=FORM_LORE[form]+FAMILY_LORE[family],family=family,form=form,trait=family,island=(family//3+form)%3,area=form//4,tide=tide))
assert len(rows)==108 and len({x['name'] for x in rows})==108
lines=['extends RefCounted','', '# Original Tidebound ecology catalogue: 108 species, nine silhouette families, twelve structural forms.','const SPECIES = [']
for row in rows:
 parts=[]
 for key,value in row.items():
  rendered='Color("'+value+'")' if key=='color' else json.dumps(value,ensure_ascii=False)
  parts.append(json.dumps(key)+':'+rendered)
 lines.append('\t{'+', '.join(parts)+'},')
lines+= [']','',islands]
path.write_text('\n'.join(lines))
with (ROOT/'docs/PET_CATALOG.csv').open('w',newline='') as f:
 writer=csv.DictWriter(f,fieldnames=['id']+list(rows[0]))
 writer.writeheader()
 for i,row in enumerate(rows):writer.writerow({'id':i+1,**row})
print('Built',len(rows),'original species entries')
