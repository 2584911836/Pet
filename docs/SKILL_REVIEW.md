# 游戏技能核验与采用记录

核验日期：2026-10-18（北京时间）。名称相同不代表同一个作者或版本；视频中的安装量与排名未得到可核验的数据源支持。skills.sh 与 GitHub API 的连接被当前代理拒绝，因此改用可访问的 GitHub 页面、原始文件和 Git 仓库树核对，未绕过网络策略。

| 用户提供的名称 | 核验结果 / 具体来源 | 对本项目的决定 |
|---|---|---|
| higgsfield-game-generation | [JurisLM 镜像](https://github.com/jurislm/higgsfield-plugin/tree/main/skills/higgsfield-game-generation)中存在；官方 higgsfield-ai/skills 当前 HEAD 未发现同名目录 | 不安装：主要面向浏览器游戏与付费 CLI 资产生成，需要额外认证，不替代 Godot |
| game-engine | 名称过于通用，未定位到视频所指的唯一同名 SKILL.md 上游 | 不安装不明来源；采用已核验的 Godot 专用模式技能 |
| multiplayer-game | 找到相关多人游戏技能集合，但未确认视频对应的唯一同名实现 | 当前是离线单机，不安装 |
| game-developer | [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills/blob/main/skills/game-developer/SKILL.md)存在同名技能 | 偏 Unity/Unreal，与 Godot 不直接匹配，不安装 |
| game-ui-design | [Game-UI-Extension](https://github.com/guiguiyan930-source/Game-UI-Extension/blob/main/game-ui-design/SKILL.md)存在同名技能；其他集合也有同名项 | 有用，但与已安装 UI/UX 技能重叠，先不重复安装 |
| game-design-theory | [custom-plugin-game-developer](https://github.com/pluginagentmarketplace/custom-plugin-game-developer/blob/main/skills/game-design-theory/SKILL.md)存在 | 使用自定义许可证；商业项目暂不引入 |
| game-feel | [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-feel/SKILL.md)存在，Apache-2.0 | 已安装：伤害反馈、动态效果分级、减少动态效果设置 |
| game-ui-ux | [同一集合](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ui-ux/SKILL.md)存在，Apache-2.0 | 已安装：焦点、布局缩放、菜单状态和可达性 |
| threejs-game-ui-designer | [threejs-game-skills](https://github.com/majidmanzarpour/threejs-game-skills/blob/main/skills/threejs-game-ui-designer/SKILL.md)存在 | 针对 Three.js，不为此改变 Godot 技术栈 |
| develop-web-game | 多个目录索引提及 OpenAI 技能；已核验 openai/skills 当前 HEAD `49f948faa9258a0c61caceaf225e179651397431` 的文件树不含同名目录 | 当前版本未核验到，不从不明镜像安装；本项目也非网页游戏 |

额外采用：[wshobson/agents 的 godot-gdscript-patterns](https://github.com/wshobson/agents/tree/main/plugins/game-development/skills/godot-gdscript-patterns)，MIT，适用于 Godot 4 的类型、场景、信号与状态模式。

## 实际安装

位置为 `.agents/skills/`，所有来源固定在完整提交 SHA，许可证与可选 NOTICE 一并保留。`sources.json` 记录原始文件 SHA256，可重复核验。只安装 Markdown 指南与引用文档，没有运行第三方安装脚本、CLI、付费服务或仓库中的代码。

- game-feel、game-ui-ux：`0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd`。
- godot-gdscript-patterns：`044b4b21f083948e69ec878a7b07c8d0951a6ffa`。

原文部分示例注明 Godot 4.7，本项目仍固定在 4.6.3；仅采用已在实际引擎验证的接口，不照搬示例中的版本假设。技能是开发参考，不是游戏运行依赖；Godot 源码 ZIP 无需携带它们。

## 本轮已落实

- 晃动按强度衰减，只改变绘制位置，不移动地图角色或改变命中逻辑。
- 提供“减少动态效果”选项，并保存设置。
- 战斗按钮提供明确焦点与输入锁，防止动画期间重复出招。
- 固定参考画布和保留纵横比，针对不同窗口尺寸进行图形验证。
- 存档先完整校验，再更新游戏状态；损坏主存档可恢复已校验的上一份备份。

这些改进不等于已完成商业验收。100 种原创宠物、美术品质、内容长度与真人试玩还需继续推进。
