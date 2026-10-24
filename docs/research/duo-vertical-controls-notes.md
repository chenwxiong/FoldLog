# Duo Vertical controls 核对记录

核对日期：2026-10-24。来源为用户已打开的 [Apple HIG 官方页面](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo#Vertical-controls)，通过浏览器读取当前渲染的正文；此前命令行抓取失败不再代表本节不可访问。

以下为与本轮修改直接相关的原文摘录：

> In general, don’t override the default bar placement.

移除 App 全局的 `toolbarVerticalBehavior(.disabled)`，使用系统 TabView 与导航默认布局。

> The exception is the inner display in portrait, which has enough vertical space to keep standard horizontal bars.

纵向侧栏并非所有姿态下都要强制出现；保持系统决策。

> When two apps share the inner display with Split View multitasking, each one places controls along its outer edge, so the left app has controls on the left.

用户提供的双栏图示表示两个 App 的系统分屏；App 内设置分类与详情是独立的内容分栏。

> Use safe areas to make sure controls don’t cover your content, including controls on the opposite edge, like when two apps share the inner display with Split View multitasking.

内容遵循系统安全区域；设置分栏不再嵌套额外的外层 NavigationStack。

> Labels that include text stay in a horizontal bar, so prefer a symbol wherever one works.

目标编辑的文字操作“取消 / 保存”保留系统水平栏；原生 Sheet 用于单个编辑任务。页面同时要求标准工具栏顺序、相关项成组、保留常用操作与系统溢出菜单。本 App 当前主导航为含标题与符号的三个原生 Tab，未自制侧栏或溢出菜单。

本记录仅涵盖所列规则与本轮相关实现，不是完整 Duo HIG 或真机验收报告。
