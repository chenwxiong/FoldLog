# 折记 0.1 验证记录

日期：2026-10-24。最新变更为按用户截图保留今日与剩余、移除三个冗余信息项的小组件；下方保留此前 UI、导航与图标记录。构建环境：Xcode 27.1（27A9275），iOS 27.1 SDK。

## 今日与剩余精简展示（当前版本）

2026-10-24，用户截图明确要求今日折叠和剩余次数都保留，只删除上限数值、更新时间、右上角演示。已恢复今日主数字、金色剩余及底部已用进度条，圆形 / 单行同时展示两项；组件名称恢复“今日折叠”，继续沿用 `FoldLog.Count`。下节只剩余的旧版本来自助手误解，不作为产品决策。

| 验证 | 结果与证据 |
| --- | --- |
| 375pt 状态和实际桌面挂载 | `WidgetSummaryCompact.xcresult` 2 项通过。状态流程同时断言今日与剩余，覆盖未设目标、达到 / 超出、六位数、不可用及深浅色；系统真实小号显示今日 1 / 剩余 2，点击进入今日且今日次数保持 1 |
| Duo 画廊与锁屏预览 | `WidgetSummaryDuo.xcresult` 1 项通过，运行时警告为空；人工检查正常数字、今日 123456 / 剩余 876543、圆形 / 单行与深浅色。两项数字完整，未显示上限数值、更新时间或演示角标 |
| 数据与恢复 | 原始档案、三类计数、目标生效、共享快照和刷新逻辑未改，未重复未修改的核心数据测试。临时签名 Debug 测试构建通过；两台 Duo 和小屏开发预览覆盖安装并正常启动，恢复各自普通档案的共享投影，未卸载或重置普通数据 |

截图：[实际桌面小号](widget-summary-home-system.png)、[浅色](widget-summary-light.png)、[深色](widget-summary-dark.png)、[未设目标](widget-summary-unset.png)、[六位数](widget-summary-large.png)、[锁屏浅色](duo-widget-summary-lock-light.png)、[锁屏深色](duo-widget-summary-lock-dark.png)、[锁屏六位数](duo-widget-summary-lock-large.png)。[卡片局部](widget-summary-card-light.png)仅裁剪自原生浅色实图。375pt 画廊使用匹配的 XCTest 附件，Duo 使用 simctl 获取激活内屏；内容未重绘，数据为隔离测试 / 示例记录。

未设目标时保留今日数字、剩余显示“—”及“未设目标”，隐藏进度；达到和超出时剩余保持 0。读档不可用、暂停、待同步保留必要短提示；App 来源、卡片外示例提示及 VoiceOver 来源继续保留。375pt 目标开关仍有既存 SwiftUI frame 警告；本轮未声称修复。锁屏图为共用原生视图预览，并非真机锁屏挂载验收，刷新仍由系统调度。

## 仅剩余次数的误解版本（已纠正）

2026-10-24，助手将“有剩余次数就好”误读为删除今日次数，产生了下述只剩余的版本；用户随后以截图澄清必须同时保留今日与剩余。本节仅记录该误解版本的实际验证，不代表用户确认的产品要求。桌面小号正常状态只有“剩余折叠”标题和金色大数字；不再展示今日已折叠、上限或进度。圆形 / 单行也仅展示剩余。展示名称改为“剩余折叠”，继续沿用 `FoldLog.Count`，无需重新添加此前统一组件。

| 验证 | 结果与证据 |
| --- | --- |
| 375pt 状态与实际桌面挂载 | `WidgetRemainingCompact.xcresult` 2 项通过。目标内、未设目标、达到 / 超出、大数字、不可用和深浅色均通过；系统小号实际显示“剩余折叠 2 次”，点击回到今日且原今日次数仍为 1 |
| Duo 画廊与锁屏样式 | `WidgetRemainingDuo.xcresult` 1 项通过，运行时警告为空。人工复核桌面 / 圆形 / 单行的正常数字、六位数 876543 和深浅色，无截断；不显示更新时间或演示标签 |
| 数据边界与编译 | 仅修改共用视图、组件展示名称、画廊说明与相关界面断言。计数、目标、共享文件格式、刷新及来源隔离未改，未重复未修改的核心数据测试。临时签名 Debug 测试构建通过，正常覆盖安装并启动于两台 Duo 和小屏预览，恢复各自真实共享投影；未卸载或重置普通档案 |

未设目标显示“—”及“未设每日上限”；达到或超出都显示 0，计数继续。读档不可用、暂停或跨日待同步仍有必要的简短提示。组件内不显示演示标签，App 的来源说明、画廊卡片外的示例说明和 VoiceOver 来源播报继续保留。

精选截图：[真实桌面挂载](widget-remaining-home-system.png)、[浅色](widget-remaining-light.png)、[深色](widget-remaining-dark.png)、[无目标](widget-remaining-unset.png)、[六位数](widget-remaining-large.png)、[锁屏浅色](duo-widget-remaining-lock-light.png)、[锁屏深色](duo-widget-remaining-lock-dark.png)、[锁屏六位数](duo-widget-remaining-lock-large.png)。[卡片局部](widget-remaining-card-light.png)仅裁剪自原生浅色实图；375pt 画廊使用对应 XCTest 附件，Duo 使用当前激活屏幕的 simctl 截图。图片数据为隔离测试 / 示例数据，未重绘组件内容。

375pt 目标开关仍有既存 SwiftUI frame 警告，本轮没有声称修复。测试结束后的本次 `simctl diagnose` 子进程停滞，确认两项测试已通过后仅停止该诊断子进程；xcodebuild 正常退出 0，结果包确认 Passed。锁屏图片仍为共用原生视图预览，不能视为真机锁屏或后台采集验收；刷新仍受系统调度。

## 今日与剩余合并组件（此前版本）

2026-10-24，按用户要求仅保留一个“今日折叠”组件：桌面小号以今日次数为主数字、金色剩余为次级数字，附上限、已用进度与更新状态；锁屏圆形 / 单行同时展示今日及剩余，整体轻点进入今日。沿用 `FoldLog.Count`，移除独立 `FoldLog.Remaining`；此前开发版的剩余组件需重新添加。计数引擎、目标生效规则、原始档案与共享快照格式未改。

| 验证 | 结果与证据 |
| --- | --- |
| 联调、画廊与辅助字号 | `WidgetCombinedAccepted.xcresult` 4 项通过：共享记录、目标保存、来源切换、清空、深链、六种示例状态、深浅色与最大辅助字号。属于本轮初次整合版本；随后补验如下 |
| 桌面六位数及系统挂载 | `WidgetCombinedFinal.xcresult` 2 项通过。实际系统小号显示演示折叠 1 / 剩余 2 / 上限 3，点击进入今日；菜单已关闭，未用画廊冒充系统挂载。六位数上限移至底行，今日 123456 / 剩余 876543 / 上限 999999 均完整显示 |
| Duo 界面与锁屏预览 | `WidgetCombinedDuoFinal.xcresult` 1 项通过；截图复核发现圆形在六位数时仍省略，修正后以 `WidgetCombinedCircularAccepted.xcresult` 为准，1 项通过，运行时警告为空。圆形标签独立于 Gauge 的内部尺寸约束，今日与剩余均完整显示，正常数字及深浅色已复核 |
| 状态 | 未设目标显示剩余“—”且无进度；达到上限显示剩余 0；超出显示剩余 0 和超出次数；待同步显示“—”并引导打开 App。画廊示例不写入档案 |
| 编译与恢复 | 最新临时签名 Debug 构建通过，App 与扩展覆盖安装于两台 Duo 和 375pt 开发预览模拟器，正常启动以恢复各自的共享投影；未卸载 App 或重置普通档案。本轮未重复 Release 真机目标编译或未修改的数据测试 |

精选截图：[真实桌面挂载](widget-combined-home-system.png)、[浅色](widget-combined-light.png)、[深色](widget-combined-dark.png)、[未设目标](widget-combined-unset.png)、[超出上限](widget-combined-exceeded.png)、[桌面六位数](widget-combined-large.png)、[Duo 深色](duo-widget-combined-dark.png)、[Duo 六位数](duo-widget-combined-large.png)、[锁屏浅色](duo-widget-combined-lock-light.png)、[锁屏深色](duo-widget-combined-lock-dark.png)、[锁屏六位数](duo-widget-combined-lock-large.png)。[卡片局部](widget-combined-card-light.png)仅裁剪自浅色实图，未重绘内容。375pt 画廊采用对应 XCTest 附件，避免异步截图延迟误截到下一步状态菜单；Duo 通过 simctl 取得当前激活屏幕。

中间截图复核还发现 Gauge 的默认标签与自定义中心重叠，最终已隐藏 Gauge 自身标签；上述最终截图和 `WidgetCombinedCircularAccepted.xcresult` 替代中间 `WidgetCombinedCircularFinal.xcresult` 的样式结果。测试断言检查完整无障碍标签，不能单凭测试通过判断可见文字完整，因此另人工核对上述六位数实图。

目标开关仍触发既有的 SwiftUI `Invalid frame dimension (negative or non-finite).` 警告，`WidgetCombinedFinal.xcresult` 保留该诊断；本轮未声称解决。锁屏截图为 App 内共用原生视图预览，并非真实 Duo 锁屏挂载；以上模拟器流程不证明真机铰链连续性或后台采集。组件仍只显示已保存记录，刷新受系统调度。

## Duo 纵向控件（当前版本）

2026-10-24，按用户提供的 [Vertical controls](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo#Vertical-controls) 修正此前全局水平导航的处理。

- 已移除 `HorizontalNavigationLayout` 和 `toolbarVerticalBehavior(.disabled)`。原生 TabView / NavigationSplitView 根据系统自动选择横纵布局与边缘；宽屏分类与详情分栏继续保留。官方双 App 图示表示系统 Split View，各 App 控件位于各自外侧，不表示本 App 应创建两条导航栏。
- 今日、设置和组件链接共用 `GoalEditorSheet`，使用系统 `.presentationSizing(.form)`。文字“取消 / 保存”保留系统布局；草稿有修改时，取消提示确认放弃，并阻止未保存状态下的交互下拉关闭。下拉本身不弹出放弃确认。
- `DuoVerticalFinal.xcresult` 两项测试通过：自动纵向导航、链接打开目标、键盘、放弃草稿与保存读回；设置分类与规则详情切换、旋转、标题避让、浅色 / 深色、辅助字号单列及进入目标编辑。
- `DuoVerticalCompactAccepted.xcresult` 一项测试通过：375pt 开发预览中的同一目标编辑与保存流程。此前两次失败分别来自开关边缘定位和原生返回按钮 AX 类型，最终测试使用适合原生控件的定位；未为此改造产品控件。
- 注入到根视图的测试大字号未传入 Sheet，因此另将 Duo 模拟器的系统字号设为最大辅助字号，人工检查原生目标表单、开启开关、滚动后查看说明；截图单独标为系统字号。检查后已恢复原系统字号。
- 最新临时签名 Debug 构建通过，并覆盖安装、正常启动于两台 Duo 模拟器和小屏开发预览；普通档案未重置。核心计数、组件尺寸及图标未改动，未重复全量业务测试。
- 本轮已通过用户打开的浏览器读取官方 Vertical controls 正文，摘录见 [核对记录](../docs/research/duo-vertical-controls-notes.md)。目标开关仍有既存的 SwiftUI frame 运行时警告；本轮没有将其报告为解决。真实硬件的内外屏切换和铰链连续性仍待验证。

最新截图：[纵向导航与今日双列](duo-vertical-today.png)、[设置分栏](duo-settings-split-light.png)、[深色分栏](duo-settings-split-dark.png)、[原生目标表单](duo-goal-form-light.png)、[数字键盘](duo-goal-form-keyboard.png)、[放弃确认](duo-goal-discard-confirmation.png)、[系统最大辅助字号](duo-goal-system-largest-text.png)、[大字号滚动](duo-goal-system-largest-text-scrolled.png)。图片均来自模拟器实际显示，未经内容重绘。

## 暖白连页 00 图标（当前版本）

2026-10-24，根据“图标黑色看着不友好”的反馈完成第四轮图标调整。

- 默认底板为暖白 `#F1E9DC`，深色底板为稍暗的暖米灰 `#DDD4C4`；数字为可可灰。连续书页轮廓、定制双零、香槟金下缘及数字翻角保持一致。
- Icon Composer 使用 `fill-specializations` 同时定义默认与深色填充。深色采用明确的实色，避免自动渐变生成黑底；两套设计均成功导出默认、深色、浅色着色、深色着色、浅色透明、深色透明六种外观。已检查主方案的 60 / 40 / 29pt 缩小效果。
- `scripts/make-icon.py` 与 `scripts/make-icon.swift` 顺序执行成功；当前 `.icon` 与生成主方案一致。三张备用 PNG 均为 1024 × 1024、sRGB、RGB 无透明通道、无预裁圆角；BrandMark 采用同一份连续书页与数字路径。
- Debug 模拟器构建、Release 真机目标编译均退出 0。产物主图标均为 `FoldLogIcon`，Widget 扩展仍完整嵌入；Release 最低系统版本保持 27.1。日志：`icon-warm-debug.log`、`icon-warm-release.log`。Release 关闭签名，仅验证编译。
- 最新 App 已覆盖安装并成功启动于两台 iOS 27.1 / iPhone Duo 模拟器（`A6C9F7A1-DCCD-49EB-9FF7-BAA1FD88F127`、`2E996C19-DF50-47AB-8CD3-CCA1EC61D417`）。未卸载 App 或清空普通档案。
- 使用 Device Hub 自带 Screenshot 按钮保存外屏主屏，确认实际系统图标为暖白新版；[桌面实图](../design/app-icon/v4-warm-ivory/duo-home-screen.png)未经内容重绘。深色、着色与透明的检查来自 Icon Composer 原生导出，不等同于这几种桌面模式全部实机验收。
- 本轮修改限于图标资源、生成工具、兼容提示的品牌底板及说明；未修改计数、目标、分栏或小组件业务逻辑，沿用此前测试结果，未重复全量业务测试。动态光照仍需真机检查。

[新版与新旧对照](../design/app-icon/v4-warm-ivory/icon-review.png)、[素材与重建说明](../design/app-icon/README.md)。

## Duo 设置页分栏修复（此前验证）

2026-10-24，针对实际 Duo 内屏中设置表单被拉长、纵向标签栏遮挡标题的问题补验。本机现已具备 iOS 27.1 / iPhone Duo 模拟器，以下结果更新了本文末尾此前缺少运行时的环境记录。

- 设置页在可用宽度至少 700pt、非辅助字号时使用原生 NavigationSplitView：左侧分类，右侧对应表单；窄屏和辅助字号使用完整表单。分类状态及编辑弹层由外层持有，复用原有 AppStore。
- 此前曾通过 toolbarVerticalBehavior(.disabled) 采用水平系统导航。该处理现已移除，恢复系统自动的横纵布局；设置页自行管理导航、移除外层重复 NavigationStack 的结构保留。最新验证见下文“Duo 纵向控件”。
- 最新 Debug 模拟器构建通过。Duo 上目标验证与保存、历史详情、计数重启保存、记录来源隔离和原有深浅色 / 横屏流程通过；375pt 的 iPhone SE 3 开发预览中，目标验证、键盘收起、保存和历史详情也通过。
- `DuoSettingsAccepted.xcresult` 的分栏专项最终通过，运行时警告为空：分类切换、规则详情、目标弹层、旋转后保留分类、深浅色、辅助字号回退及滚动后进入目标编辑。新增 SettingsSymbol 的 ScaledMetric 容器，修复辅助字号下图标与标签相挤的问题。其他流程结果见 `DuoSplitLayout-Final.xcresult` 中通过的 4 项既有流程、`SettingsCompactRegression.xcresult` 中通过的 1 项小屏流程；分栏专项此前失败的自动化操作已由最终结果替代。
- Duo 模拟器可能在设备方向改变后仍保留较宽的内屏窗口，不能把 `.portrait` 直接当作窄屏；检查以实际可用空间为准。辅助字号明确回退为单列，375pt 预览用于补验窄屏。
- XCTest 的默认屏幕截图在此 Duo 运行时可能取得未激活的外屏黑帧；精选截图通过 simctl 获取当前激活内屏，页面内容未经重绘。[浅色分栏](duo-settings-split-light.png)、[深色分栏](duo-settings-split-dark.png)、[辅助字号单列](duo-settings-largest-text.png)。
- 目标开关场景仍能触发此前已记录的 SwiftUI `Invalid frame dimension (negative or non-finite).` 警告，iOS 27.1 也可复现；本轮没有把它报告为已解决。真实硬件铰链、内外屏切换和持续采集仍未验证。

## App Icon 连页与计数迭代（第三轮历史记录）

- 第三轮曾采用黑底「连页 00」，现由上述暖白版本替代：书页由单条连续轮廓构成，中间无独立铰链、分隔线或白金材质拼接。定制双零通过微倾表现页片方向，右侧 0 以香槟金翻角提示翻页计数；另保存无翻角的备选。
- `FoldLogIcon.icon` 更新为数字、完整书页、金色下缘三张 SVG。数字均为原创路径，不含 SVG 文本节点或 SF Symbols；`00` 为静态品牌标记，真实次数仍在 App 内查看。
- Icon Composer 成功导出两种方案各 5 种外观。已检查默认、深色、着色与透明呈现，以及 60 / 40 / 29pt 缩小效果；备用 PNG 与透明 BrandMark 同步使用相同几何路径。
- iOS 27.1 / iPhone Duo Debug 构建、覆盖安装和启动通过，外屏主屏截图确认新图标；未卸载 App 或清空普通档案。本轮仅更新图标及生成工具与文档，未修改业务逻辑，未重复全量核心和 UI 测试。
- [新版与备选](../design/app-icon/v3-connected-zero/icon-review.png)、[外屏主屏实图](../design/app-icon/v3-connected-zero/duo-home-screen.png)、[素材及重建说明](../design/app-icon/README.md)。

## App Icon 材质迭代（第二轮历史记录）

- 第二轮曾采用「折光」，另提供「对页」备选；已由上述「连页 00」替代。该轮新增原创曲线路径、珍珠白 / 香槟金色面渐变，移除刻度细槽，原始素材继续归档保留。
- 工程接入 `FoldLog/FoldLogIcon.icon`；两张透明 SVG 前景与系统背景 / 材质配置完整。构建产物 `CFBundlePrimaryIcon.CFBundleIconName` 已确认是 `FoldLogIcon`，不再使用第一轮的扁平 PNG 主图标。
- Icon Composer 成功导出两种设计的默认、深色、着色、浅色透明与深色透明预览，共 10 张。检查主方向的 60 / 40 / 29pt 缩小效果；原有资产目录另同步保留 3 张 1024 × 1024、sRGB、不透明、无圆角裁切的 PNG。
- iOS 27.1 / iPhone Duo（`A6C9F7A1-DCCD-49EB-9FF7-BAA1FD88F127`）Debug 构建、覆盖安装和启动通过；外屏主屏实际截图确认显示新的分层图标。未卸载 App 或清空普通档案。
- 本轮改动限于图标素材、生成工具、图标构建设置与文档，未修改计数业务逻辑；未重复执行核心 / 全量 UI 测试。下列原有测试结果保留原来的验证范围。
- [材质与外观对比](../design/app-icon/v2-fold-light/icon-review.png)、[Duo 外屏主屏](../design/app-icon/v2-fold-light/duo-home-screen.png)、[源文件与重建说明](../design/app-icon/README.md)。

## Duo 专属与 App Icon 更新

- 产品范围已限定为 iPhone Duo。Release 产物的 `MinimumOSVersion` 为 `27.1`，`UIDeviceFamily` 为 `[1]`；关闭 Mac / Vision 兼容入口，运行时按 Duo 型号与系统版本限制进入。
- `swift test` 重新运行，9 项全部通过：原有 8 项计数 / 存储测试，加 1 项 Duo 型号、系统版本与设备类别策略测试。
- `DuoOnlyIcon.xcresult` 的 3 项界面测试全部通过，运行时警告为空：普通 iPhone 被拦截、预览中的计数与重启保存、演示和设备记录隔离。兼容提示图见 [非 Duo 提示](unsupported-device.png)。该流程不包含上一轮有警告的目标开关场景。
- 最新 Debug 模拟器构建与 Release 真机目标编译通过，后者关闭签名、未安装到真机。检查编译产物确认预览参数只存在于 Debug 模拟器的应用代码中，Release 不包含该入口。普通模拟器的预览仅通过 Debug 专用参数开启。
- 第一轮曾制作 3 个方向、默认 / 深色 / 着色各 1 套，共 9 张 PNG 及对应 SVG；当时接入 A“折页刻度”的扁平素材，检查过普通模拟器主屏与兼容提示。该历史方案已被上述「折光」原生分层图标替代，原始素材保留在设计目录。
- [图标设计与源文件](../design/app-icon/README.md)、[Duo 范围与技术边界](../docs/仅Duo兼容范围.md)。App Store 精确机型下载过滤与真实 Duo 仍需发布前核验；仅声明 iPhone 设备族不代表完成商店筛选。

以下保留黑白金 UI 迭代的完整检查记录；其中普通机型均为开发预览，不构成支持这些机型的承诺。

## 结果

- 核心计数与存储逻辑未修改，沿用此前 `swift test` 的 8 项通过结果。包含用户确认的 10 组转移例子、1 秒边界、重复回调、跨午夜的延迟计时、观测中断、档案保存、来源隔离、目标历史和损坏文件处理。
- 最新 UI 的模拟器构建通过。
- 最新源码的 `generic/platform=iOS` 构建通过，关闭签名；这是编译验证，未安装到真机。
- iPhone 17 Pro 完整 5 项原生界面流程通过；iPhone SE 3 的 3 项专项检查通过。最终图表 / 目标表单调整后，同一目标与历史场景在两台设备分别补验通过。

| 本轮界面场景 | 通过设备 / 运行 |
| --- | --- |
| 半开确认、全开、合拢与重新启动后的保存 | iPhone 17 Pro / iOS 26.5，GoldUITests-Final |
| 演示与设备记录隔离 | iPhone 17 Pro / iOS 26.5，GoldUITests-Final |
| 最大辅助字号下可触达的模拟按钮 | 两种机型 / iOS 26.5，GoldUITests-Final、GoldSmallPhone |
| 浅色、深色、最大字号及横屏截图流程 | 两种机型 / iOS 26.5，GoldUITests-Final、GoldSmallPhone |
| 目标无效输入、键盘收起、保存与历史详情 | 两种机型 / iOS 26.5，GoldControlsFinal（同一测试在两台设备各通过一次） |

人工检查了黑白金浅色与深色三页、最大辅助字号、375pt 小屏、横屏双列、目标编辑与历史截图。图表时间轴覆盖完整自然日，避免午夜之后当天柱形被裁切；日期标签使用紧凑格式并保留完整末端日期。原生横屏截图采用整屏截图。

本轮修复了目标行只有文字部分可点击的问题，整行现在都有点击范围。目标数字键盘提供“完成”。计数规则、来源隔离与数据目录保持原有行为。

### 尚存诊断

在 iOS 26.5 两种模拟机型上，开启目标开关时仍会出现一条 SwiftUI 的 `Invalid frame dimension (negative or non-finite).` 运行时警告。已根据日志定位触发步骤，并检查表单结构与键盘工具栏；尚未确认根因。上述流程均通过，截图未发现对应的可见裁切或控件不可操作，但不能称为无警告验证。需在 iOS 27.1 环境复查。

Xcode 另输出宿主系统版本解析与调试器版本查询诊断，未阻止编译或测试。小屏测试结束后的自动诊断收集曾停滞，已仅终止该次 `simctl diagnose` 子进程以完成结果归档；3 项测试本身均已正常结束并通过。

## 预览

- [四屏预览](preview.png)：浅色今日、深色今日、历史、设置的真实模拟器截图组合；不同页面来自独立测试步骤，历史记录和目标由模拟操作产生。
- [今日](today-light.png)、[小屏今日](small-today-light.png)、[历史图表](history-with-records.png)、[设置目标](settings-with-goal.png)、[每日详情](day-detail-with-goal.png)。
- [深色今日](today-dark.png)、[深色历史](history-dark.png)、[深色设置](settings-dark.png)、[目标编辑](goal-editor.png)。
- [宽屏今日](today-landscape.png)、[宽屏历史](history-landscape.png)、[小屏横屏](small-today-landscape.png)、[最大辅助字号与深色](today-dark-largest-text.png)。

普通运行初次启动仍从 0 开始，测试数据使用单独目录；已有普通档案未被清空。本轮结束时已用启动脚本成功构建、安装并启动更新后的普通演示 App；在当前 Xcode 中图形入口为 Device Hub。预览图可在项目根目录用 `swift scripts/make-preview.swift` 重新合成。

## 尚未验证

此前 Apple HIG 网页及镜像连接失败，未能读取 Duo 专页正文；使用本地 HIG 与本机 SDK 完成通用 iOS 设计核对，不能声称已核对 Duo 专项全部条款。目前已安装 iOS 27.1 运行时，并完成上述 Duo 模拟器的启动、图标与系统呈现检查。

真实 Duo 铰链、内外屏场景切换、后台、锁屏和退出后的连续采集未验证；普通机型横屏与模拟按钮不能代替这些测试。iPad 不在支持范围内。体验版没有全局系统栏、JSON 导入恢复、TestFlight 或 App Store 发布。

完整 xcresult、原始截图和调试日志保留在本地 artifacts 目录，已通过 .gitignore 排除；源代码与以上精选图片可以独立保存。

## 桌面与锁屏小组件 · 2026-10-24

新增原生 WidgetKit 扩展，提供“今日折叠”“剩余折叠”两种入口，支持桌面小号 / 中号和锁屏圆形 / 矩形 / 行内。原始档案路径不变，共享目录只写入统计投影。App 内设置增加样式与添加说明。

| 验证 | 结果与证据 |
| --- | --- |
| 核心数据 | `swift test` 17 项通过，其中 8 项覆盖组件统计、未设 / 达到 / 超限、次日目标、跨日、夏令时、来源隔离、清空、损坏投影和链接路由 |
| Duo 联调 | `WidgetIntegrationAccepted.xcresult` 两项通过：次数 / 目标保存、共享文件、来源切换、清空、冷启动链接、深色与辅助字号 |
| 共享内容 | 宿主读取真实 App Group 文件确认：保存后 demo 折叠 1 / 上限 3；切到 device 后 0 / 无目标；清空 demo 后 0 / 无目标。明细在 `widget-sync-checks.json` |
| 辅助字号 | `WidgetSystemAccepted.xcresult` 中最大字号样式页测试通过；组件画布保持固定系统尺寸，页面说明随辅助字号放大，完整数值通过 VoiceOver 标签提供 |
| 375pt 样式 | `WidgetCompactFinal.xcresult` 浅色 / 深色、桌面与锁屏样式流程通过；最终样式截图在 `WidgetStylesAccepted.xcresult` |
| 系统桌面挂载 | `WidgetHomeFinal.xcresult` 在 375pt 开发预览模拟器通过；系统中号组件实际显示“折叠 1、剩余 2、上限 3”，轻点次数进入今日；不是 App 内仿制截图 |
| 编译与安装 | Debug 临时签名构建、Release 关闭签名的真机目标编译通过；扩展已嵌入 App，两台 Duo 模拟器安装并正常启动，组件投影恢复为各自正常的设备来源 |

精选截图：[桌面系统实际挂载](widget-home-system.png)、[375pt 浅色](widget-compact-light.png)、[375pt 深色](widget-compact-dark.png)、[锁屏样式预览](widget-lock-styles.png)、[深色锁屏样式预览](widget-lock-styles-dark.png)、[最大辅助字号](widget-gallery-largest-text-scrolled.png)。截图中的演示数字已明确标识。

Duo 的桌面自动化初次因命中隐藏图标而失败，后续改用独立小屏预览模拟器验证系统挂载；Duo App 内布局、共享与链接联调独立通过。锁屏图片来自与扩展共用的 SwiftUI 原生视图预览，尚未在真实 Duo 锁屏挂载。现有目标开关仍可触发前述 SwiftUI frame 警告，组件的样式与桌面挂载测试没有新增运行时警告。

组件不会采集后台开合。保存后请求系统刷新，实际刷新受 WidgetKit 调度；午夜条目按档案时区预先生成，但不能承诺每次折叠即时更新或后台无漏记。真机签名需同一团队注册共享组，配置说明见 [小组件文档](../docs/桌面与锁屏小组件.md)。

## 最小尺寸组件 · 2026-10-24

按用户追加要求，桌面仅保留系统小号，锁屏保留圆形与单行；移除中号和矩形及对应预览。上节中号挂载结果保留为先前版本的历史证据。今日折叠小号仍可同时显示当前次数、剩余次数和上限；两种组件均可跳转今日或目标。

| 验证 | 结果与证据 |
| --- | --- |
| 375pt 界面与联调 | `WidgetMinimalAccepted.xcresult` 中 3 项 `WidgetUITests` 均通过：保存 / 目标 / 来源切换 / 清空 / 链接，以及浅色 / 深色 / 最大辅助字号 |
| 系统小号挂载 | `WidgetMinimalHome.xcresult` 1 项通过，无运行时警告；确认形状为小号、读取共享记录、轻点进入今日。截图为系统真实挂载，显示演示 0 次、未设上限 |
| 桌面菜单定位 | 上一批系统项因 App 只在资源库而缺少尺寸入口失败；脚本补充“添加到主屏幕”后独立重跑通过。实际尺寸菜单仅小号可用 |
| 文字完整性 | 圆形的演示标签允许在固定画布内缩小，避免省略；两种外观的完整锁屏样式均已检查 |
| 编译与运行 | 最新 Debug 临时签名测试构建、Release 关闭签名的真机目标编译通过；最新 App 已安装并正常启动于两台 Duo 模拟器 |

最新截图：[系统桌面小号](widget-home-small-system.png)、[浅色](widget-minimal-light.png)、[深色](widget-minimal-dark.png)、[锁屏样式预览](widget-minimal-lock-light.png)、[深色锁屏样式预览](widget-minimal-lock-dark.png)。锁屏图片仍为 App 内共用原生视图预览，不能视为真实锁屏验收。联调中的目标输入继续出现此前已有的 SwiftUI frame 警告。

Apple 审核指南 2.1(a) 要求提交前进行设备上的缺陷与稳定性测试，详见 [上架前的真机验证](../docs/体验版运行说明.md#上架前的真机验证)。本轮模拟器结果不构成折叠硬件能力、真实内外屏切换或后台计数的真机证据。
