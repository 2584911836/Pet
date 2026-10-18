# v0.7.0 素材与来源

## 游戏内素材

| 内容 | 来源与实现 | 当前状态 |
|---|---|---|
| 108 种灵兽主图 | 12 张 AI 生成/迭代透明图集，各含九个独立设计的宠物；设计档案见 `assets/pets/species_designs.json` | 全部已用于野外遭遇、战斗、捕捉、图鉴与详情 |
| 物种目录 | 逐条编写的 `species_designs.json` 编译为 `game_data.gd`；108 个物种、技能名与机械效果组合，11 类实装技能效果 | 108 条；差异性与艺术品质仍需人工筛选 |
| 原型备用美术 | `pixel_art.gd` 中的显式像素图案与结构变化 | 图片缺失时的备用图，不是当前默认美术 |
| 地图物件 | `world_objects.png`，AI 生成九件独立树木、草丛、岩石、帐篷、灯塔、船、路牌、石碑、桥梁 | 原始图集保持不变，按明确区域引用 |
| 洛汐与阿岚立绘 | `luoxi_portrait.png`、`aran_portrait.png`，AI 生成原创人物 | 档案与对话使用；地图小人为独立像素图案与行走帧 |
| 地形、航线、UI | 项目绘制代码与 Godot 控件 | 自有布局与运行逻辑 |
| 配乐与音效 | `audio.gd` 的合成器与音序列，六首 WAV 由 `bake_audio.gd` 生成 | 不含外部录音采样；仍需真人听感评估 |
| 标题插画 | `title_archipelago.png`，AI 生成的原创群岛、守灯人与同伴 | 标题插画，不是实际游戏地图截图 |
| 中文字体 | Noto Sans CJK Regular，来自系统字体包，SIL Open Font License 1.1 | 字体及完整许可一并提供 |

生成日期：2026-10-18（北京时间）。源图片未做像素修改，原始生成文件在工作区保留。游戏通过 AtlasTexture 选择区域；自动检测后对角色顺序进行了人工核对。

- 宠物图集来源与校验：`assets/pets/sources.json`。
- 其他 AI 图像来源与校验：`assets/art/PROVENANCE.json`。
- 宠物裁切：`pet_atlases.gd`、`assets/pets/regions.json`；场景裁切：`world_art.gd`、`world_regions.json`。
- 可选开发工具 `build_atlas_metadata.py` 只读取 alpha 连通区域并输出坐标，需要 Pillow/NumPy/SciPy；游戏运行与 Godot 导入不需要 Python。

## 商业审查尚未完成

生成内容和程序绘制不代替正式发行前的知识产权审查，不得宣称经过律师或平台认证。已替换九家族套形态的默认美术，保留 family/form 字段仅用于旧编号定位图集；每个物种仍需真人辨识与审美评估。

正式发行前应对名称、美术、文本逐项做近似性审查，替换有疑问的设计，并按 Steam 当时的内容调查准确披露预生成 AI 内容。若委托画师或音乐人，保留商业授权合同；不要将 AI 图像宣传为真人手绘。

`.agents/skills` 仅是开发参考，不是运行素材，许可证与固定上游提交已单独记录。
