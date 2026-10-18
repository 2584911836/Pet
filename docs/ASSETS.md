# v0.9.0 素材与来源

| 内容 | 来源与实现 | 用途 |
|---|---|---|
| 108 种伙伴 | `assets/pets/species_*.png`，12 张 AI 图集；逐种设计见 `species_designs.json` | 遭遇、战斗、图鉴与背包 |
| 标题插画 | `title_starwild.png`，AI 生成的训练师、伙伴、内陆城镇与联赛场景 | 新版标题背景，非实际关卡截图 |
| 洛汐、阿岚 | AI 生成的 `luoxi_portrait.png`、`aran_portrait.png` | 人物档案与研究员对话 |
| 茵禾、乔渡 | AI 生成的 `yinhe_portrait.png`、`qiaodu_portrait.png` | 独立 NPC 对话立绘；地图为独立小人图 |
| 场景物件 | `world_objects.png` 的树木、草丛、岩石、帐篷、路牌等区域 | 原始图集保留，旧灯塔与船舶区域不再绘制 |
| 赛场、研究站、路线、地图与 UI | Godot 原生绘制与 Control 容器 | 新世界地图和战斗布局 |
| 配乐与音效 | `audio.gd` 原创合成器与六首 WAV | 不使用外部录音采样 |
| 字体 | Noto Sans CJK Regular，SIL OFL 1.1 | 中文显示，随附完整许可 |

所有生成图片使用原始输出，未做脚本像素修改；图集通过 AtlasTexture 元数据引用。来源文件名和 SHA256 分别保存在 `assets/pets/sources.json` 与 `assets/art/PROVENANCE.json`。

旧群岛标题图已从当前资源移除，原记录可在 Git 历史查看。历史截图与测试记录只用于版本追溯，不代表当前玩法。

图像生成与程序绘制不代替正式发行前的权利、相似性和平台内容披露审查。当前素材未经商业法律认证；Godot、字体及开发技能遵循各自许可证。运行游戏不需要图片生成服务或开发用 Python 依赖。

### v0.10.0 地图绘制

新增地图地面、道路、民居、矿轨、广场、研究站与出口标记通过 `scripts/world_layout.gd` / `scripts/main.gd` 的 Godot 绘图代码生成，植被继续使用原有世界物件图集。本次未引入第三方地图贴图。
