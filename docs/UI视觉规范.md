# 折记 · 黑白金原生界面

2026-10-24。本轮根据用户指定的 Apple HIG、SF Symbols 与黑白金方向调整 SwiftUI 体验版。黑白金是本 App 的配色选择，控件材质和导航采用系统提供的外观。

## 视觉与组件

| 项目 | 实现 |
| --- | --- |
| 主文字、次数 | 系统 `.primary` 黑白色，次数使用系统圆角等宽数字 |
| 次要信息 | 系统 `.secondary`；不把浅金色用作小号正文 |
| 金色 | 浅色约 `#86621D`，深色约 `#D9B875`；增加对比度时另有更深 / 更亮变体 |
| 金色用途 | 当前选择、姿态标识、目标进度、图表柱形和可操作文字 |
| 内容背景 | 浅色中性灰白，深色黑色；卡片使用系统分组背景色 |
| 控件 | 原生 TabView、NavigationStack、NavigationSplitView、Picker、Form、Toggle、Sheet 和键盘工具栏 |
| Liquid Glass | 交由系统导航、标签栏和工具栏呈现；数据卡片使用实色内容背景 |
| 页面图标 | 全部使用 SF Symbols，替换原来的 Canvas 姿态示意图 |
| 桌面图标 | 原创“暖白连页 00”，暖白底、完整相连的珍珠书页和可可灰双零；深色采用稍暗的暖米灰底板。中间无独立铰链或材质拼接，香槟金用于下缘及数字翻角；`FoldLogIcon.icon` 使用三张透明 SVG 与系统材质，提供默认 / 深色及浅深着色 / 透明六种外观，设计与旧稿见 `design/app-icon/` |

金色与白色背景对比度约 5.57:1；金色与浅色模式徽章背景约 4.54:1；深色金色与系统深色卡片约 8.93:1。模拟按钮的文字使用系统主文字色，选中状态通过金色背景、边框、填充符号和无障碍选中属性共同表达。

## 页面层级

- 今日：日期与来源 → 当前姿态和主次数 → 三类今日汇总 → 演示控件 → 对应目标。移除重复的品牌工具栏按钮。
- 历史：来源和 7 / 30 天菜单 → 分类切换 → 期间已记录次数及图表 → 每日明细。金色柱形配中性坐标轴。
- 设置：宽屏通过原生 NavigationSplitView 展示左侧分类（记录方式、每日目标、小组件、外观、数据、关于与规则）和右侧对应表单，默认选择每日目标。窄屏保留完整分组表单。
- 目标编辑：统一使用系统表单尺寸的 Sheet，包含姿态标识、原生开关和数字输入；数字键盘提供“完成”，验证错误同时含图标和文字。修改后取消需确认放弃，未保存时阻止交互下拉关闭。

## 小组件

仅注册一个“今日折叠”组件，桌面仅系统小号。使用黑白金语义配色与系统圆角等宽数字：今日次数为主数字，剩余为金色次级数字，旁列个人上限，细进度条表示已用比例。上限达到五位数时移至底行，为剩余数字留出完整空间。未设目标显示剩余“—”；达到或超限显示剩余 0，并明确标出状态。锁屏圆形 Gauge 的中心同时显示次数与剩余，单行同时表达“折叠 × · 余 ×”，遵循系统单色 / 着色呈现。无目标、超限、演示、待同步均以文字区分，不仅靠颜色。整个组件轻点进入今日；扩展与 App 内预览共用视图，示例数据明确标识。

## 布局、可访问性与连续性

应用支持范围限定为 iPhone Duo。布局按实际可用宽度排布，用于 Duo 内外屏及窗口空间；普通机型模拟器仅作开发预览。可用宽度达到 700pt 且不使用辅助字号时，今日和历史使用双列内容，设置使用分类与详情分栏。今日和历史最大内容宽度 1080pt，设置详情表单最大宽度 640pt，分类栏宽度由系统在 220–300pt 间分配。紧凑宽度和辅助字号回到纵向结构，模拟按钮和汇总逐项纵排。

三个主页面保留系统 TabView，使用默认的自动横纵布局，不再通过 toolbarVerticalBehavior(.disabled) 全局关闭 Duo 的纵向控件。系统根据设备、窗口和方向决定控件排列及所在边缘，内容遵循相应安全区；布局重叠应在所属容器内修正。用户提供的 Vertical controls 图示中，左右两条栏分别属于并排运行的两个 App，不代表本 App 必须同时创建两条侧栏。单个 App 的今日双列与设置分类分栏独立按可用空间决定。

已从官方页面核对：外屏与内屏横向布局使用侧边控件；内屏纵向布局可以保留水平栏。两个 App 使用系统 Split View 时，各自控件靠设备外侧。页面还明确说明，带文字的操作按钮会保留水平排列，因此目标表单的“取消 / 保存”沿用系统呈现，不强行移到侧边。

设置页自行管理导航容器，不在 NavigationSplitView 外重复嵌套 NavigationStack。分类切换重置该分类的详情导航，旋转保留当前分类；目标编辑的今日、设置与组件链接三个入口共用 GoalEditorSheet，采用 presentationSizing(.form)，计数来源仍共享同一个 AppStore。

文字使用系统文本样式，主数字用 ScaledMetric，所有页面可滚动。按钮保留至少 44pt 触控范围，内容遵循安全区域；数字变化尊重“减弱动态效果”，导航和弹层使用系统交互。清空数据仍保留系统红色破坏性语义和确认流程。

## 依据与验证边界

依据本地保存的 HIG：Designing for iOS、Color、Materials、Layout、Tab bars、SF Symbols、Typography 与 Accessibility。使用本机 SDK 验证原生接口。UI/UX 技能检索的通用落地页配色 / 字体建议不适用于本项目，未套用；原生导航、控件与可访问性建议用于交叉检查。

- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Vertical controls](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo#Vertical-controls)：用户本轮提供的官方图示为纵向控件适配依据。
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)

此前直接抓取 Apple 官方页面及文档镜像遇到连接重置；本轮已通过用户打开的浏览器页面读取并核对 Vertical controls 正文，关键摘录见 [核对记录](research/duo-vertical-controls-notes.md)。本次验证覆盖导航、分栏和目标表单，未据此宣称完成 Duo 所有专项验收。2026-10-24 使用 iOS 27.1 / iPhone Duo 模拟器检查实际系统呈现；模拟器布局验证不替代真实硬件的内外屏切换与铰链连续性验证。
