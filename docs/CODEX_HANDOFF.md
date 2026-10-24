# FoldLog / 折记 · Codex 交接上下文

更新日期：2026-10-24。用途：在另一台机器或另一个 Codex 中接续本仓库，无需依赖原聊天记录。

## 当前交付状态

仓库：[chenwxiong/FoldLog](https://github.com/chenwxiong/FoldLog)，当前分支 `main`。首次完整项目提交为 `25dedee`（`feat: add FoldLog Duo app and compact widgets`）。本文件和根目录 AGENTS.md 是随后补交的接续入口，继续开发时以远端最新提交为准。

本轮任务已完成：修复 Duo 适配，增加最小尺寸桌面 / 锁屏组件，按用户提供的 Apple Vertical controls 规范恢复系统自动纵向导航，并推送 GitHub。用户随后要求把上下文也提交，供另一个 Codex 执行。

当前没有因交接而新增的产品功能任务。后续按用户的新指令继续，不把下文待验事项自动当成已授权的商店发布任务。

## 已确认的产品决策

- 工作名称：折记 / FoldLog，正式商店名称仍待核验。原生 SwiftUI 个人工具，先完成普通 App；这里的“普通 App”指应用形态，不表示支持普通 iPhone。
- 发布范围：仅 iPhone Duo，iOS 27.1+。当前型号白名单 `iPhone19,4` 来自本机 Xcode 设备配置，尚待真实设备及区域变体核对。其他机型显示兼容提示。
- 今日、累计、目标与历史按折叠（合拢）、半开、全开分别保存。不要将半开和全开直接相加命名为“展开总次数”。
- 合拢 → 半开连续停留满 1 秒才记半开 +1；不足 1 秒不记。半开已记后再全开，全开另加 1。全开 → 半开仅切换展示，不启动半开计数；再次全开仍记全开 +1。
- 重复状态回调不重复计数；首次状态仅建立基线。失去观测覆盖后取消待确认计时，恢复快照不能补造历史事件。按计数确认时间归属统计日。
- 合拢时突出今日折叠和半开 / 全开目标；半开或全开时突出相应次数，并显示共享的折叠目标。页面出现、切屏和旋转不能自行增加事件。
- 当前实现为三类独立个人每日上限，默认关闭；首次可当天生效，后续修改默认次日，关闭立即生效。达到上限仍继续计数。
- 数据本地保存，演示与设备档案分开。已有 JSON 导出，尚无导入恢复。次数不代表折痕、屏幕健康或硬件寿命。
- 用户要求最小组件：桌面仅 `.systemSmall`，锁屏仅 `.accessoryCircular` / `.accessoryInline`。保留“今日折叠”“剩余折叠”两种入口，不恢复中号或矩形。
- 用户偏好直接完成已授权工作，避免对已确定范围重复确认；界面方向为黑白金、SF Symbols 和原生系统控件。

完整计数边界及十组例子见 [计数与姿态展示规则](计数与姿态展示规则.md)。该文部分旧规划已被后续版本替代，应同时参考当前源码和本文件。

## 本轮 Duo 界面修正

用户指定的规范：[Designing for iPhone Duo — Vertical controls](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo#Vertical-controls)。已通过浏览器实际读取相关正文，关键摘录在 [规范核对记录](research/duo-vertical-controls-notes.md)。此前命令行抓取失败的历史说明不代表本节仍未核对。

- 删除 `HorizontalNavigationLayout` 及全局 `.toolbarVerticalBehavior(.disabled)`。根 TabView 保留 `.sidebarAdaptable`，由系统决定轴向、边缘和安全区域。
- 外屏与内屏横向布局采用侧边控件；内屏竖向可以保留水平栏。不要为匹配某张截图把侧栏物理位置写死。
- 官方图中的左右两条栏分别属于系统 Split View 中的两个 App。单个 App 无需创建两条导航栏；本 App 的内容双列是另一层布局。
- 设置在可用宽度至少 700pt、非辅助字号时使用 NavigationSplitView：分类与详情分栏。窄屏和辅助字号使用完整纵向表单。设置自行管理导航，不在外层重复嵌套 NavigationStack。
- 今日和历史按可用宽度使用双列，不等同于把单列表单无限拉伸。
- 今日、设置及组件目标链接共用 `GoalEditorSheet`，采用原生 `.presentationSizing(.form)`；这是系统表单意图，不保证所有设备上的尺寸都明显变小。
- 目标编辑使用原生取消 / 保存操作。文字按钮保留水平栏符合系统呈现，不必强行移到侧边。
- 修改后的取消会确认是否放弃；未保存时通过 `.interactiveDismissDisabled(hasChanges)` 阻止交互下拉关闭。下拉尝试本身不会弹出确认。保存继续正常关闭并写入档案。

最新实际效果：[今日与纵向导航](../artifacts/duo-vertical-today.png)、[设置分栏](../artifacts/duo-settings-split-light.png)、[目标表单](../artifacts/duo-goal-form-light.png)、[放弃确认](../artifacts/duo-goal-discard-confirmation.png)。

## 工程与关键文件

工程为 `FoldLog.xcodeproj`，scheme 为 `FoldLog`，无第三方依赖。最新开发环境为 Xcode 27.1 / iOS 27.1 SDK。版本 `0.1.0`，构建号 `1`。

| 位置 | 职责 |
| --- | --- |
| `FoldLog/FoldLogApp.swift` | 原生 TabView、场景生命周期、铰链入口、组件链接及共享目标弹层 |
| `FoldLog/AppStore.swift` | 单一计数上下文、半开计时、模式隔离、本地保存和组件发布 |
| `FoldLog/Core/CountingEngine.swift` | 独立状态机、单调时钟与计时边界 |
| `FoldLog/Core/RecordArchive.swift` | 事件、目标版本、时区与档案存储 |
| `FoldLog/DeviceSupport.swift`、`Core/DeviceSupportPolicy.swift` | Duo 限制和 Debug 预览入口 |
| `FoldLog/Views/TodayView.swift`、`HistoryView.swift` | 今日、自适应双列和历史 |
| `FoldLog/Views/SettingsView.swift` | 分类分栏、GoalEditorSheet、目标草稿保护 |
| `FoldLog/Core/WidgetSnapshot.swift` | 组件统计投影、共享文件、链接路由 |
| `FoldLog/WidgetSync.swift`、`FoldLogWidgets/` | App Group 发布、WidgetKit 时间线与两种组件 |
| `FoldLog/Widgets/FoldWidgetContent.swift` | 宿主预览和扩展共用的原生组件视图 |
| `FoldLog/FoldLogIcon.icon` | 当前原创“暖白连页 00”分层图标 |
| `Tests/`、`FoldLogUITests/` | 核心测试、原生 UI 和组件联调 |
| `scripts/` | 设计预览启动、工程生成、图标生成和 Duo 截图工具 |

当前标识：App 为 `app.foldlog.preview`，Widget 为 `app.foldlog.preview.widgets`，共享组为 `group.app.foldlog.preview`。深链为 `foldlog://today` 和 `foldlog://goal/closed`。更换标识时需同步 App、扩展、entitlements、共享容器及相关测试；真机签名需使用同一团队。

普通档案位于 Application Support 的 `FoldLog` 子目录；UI 测试使用 `FoldLogUITests`。组件共享目录仅保存统计投影，不迁移或覆盖原始档案。普通 UI 测试默认不发布共享组件数据，联调通过 `--widget-integration-testing` 显式启用；结束后正常启动 App 可恢复真实共享投影。

## 另一台机器如何启动

```sh
git clone https://github.com/chenwxiong/FoldLog.git
cd FoldLog
swift test
open FoldLog.xcodeproj
```

选择 FoldLog scheme 和本机具备运行时的 Duo 模拟器。普通模拟器需在 Debug 启动参数添加 `--design-preview`，也可运行 `scripts/run-preview.command`；该脚本会寻找或创建本机预览设备。不要直接使用原机器的绝对路径或模拟器 UUID。

Debug 最低 iOS 26 仅用于普通模拟器预览；Release 最低 iOS 27.1。真机和 Release 不接受 `--design-preview` / `--ui-testing` 绕过机型限制。`--check-device-support` 用于测试真实兼容拦截。

模拟器构建保留临时签名，以便系统分配 App Group：

```sh
xcodebuild -project FoldLog.xcodeproj -scheme FoldLog \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGN_IDENTITY=- build
```

`CODE_SIGNING_ALLOWED=NO` 可以做编译检查，但不能据此验证共享容器。真机选择自己的开发团队后再签名；仓库不包含团队凭据或描述文件。

## 验证证据和复跑

详细结果以 [验证记录](../artifacts/validation.md) 最新章节为准，后面的旧轮次用于留存历史，不表示其方案仍在使用。

| 已完成验证 | 结果 |
| --- | --- |
| 核心、兼容策略、组件数据 | `swift test` 最近一次 17 项通过；本轮只改导航和表单，未重复执行未修改的核心测试 |
| Duo 自动导航及草稿；分栏、旋转、深浅色与字号回退 | `DuoVerticalFinal.xcresult` 两项通过 |
| 375pt 开发预览的目标编辑、放弃和保存读回 | `DuoVerticalCompactAccepted.xcresult` 一项通过 |
| 最小组件的联调、画廊和字号 | `WidgetMinimalAccepted.xcresult` 中 3 项 WidgetUITests 通过 |
| 系统真实桌面小号挂载及点击 | `WidgetMinimalHome.xcresult` 一项通过 |
| 编译 | 最新导航已通过临时签名 Debug 测试构建；此前组件与图标版本通过关闭签名的 Release 真机目标编译，不能理解为已安装真机 |

完整 xcresult、构建产物和临时日志只保留在原开发机，已被 `.gitignore` 排除；GitHub 提供验证摘要与精选真实截图。新机器需要时重新运行，不能依赖本地结果包存在。

先获取本机模拟器 UUID：

```sh
xcrun simctl list devices available
```

将下面的 `YOUR_DUO_SIMULATOR_UDID` 替换为本机 Duo UUID；结果目录须未存在：

```sh
mkdir -p artifacts
xcodebuild -project FoldLog.xcodeproj -scheme FoldLog \
  -destination 'platform=iOS Simulator,id=YOUR_DUO_SIMULATOR_UDID' \
  -derivedDataPath build CODE_SIGN_IDENTITY=- \
  -parallel-testing-enabled NO \
  -only-testing:FoldLogUITests/FoldLogUITests/testAdaptiveNavigationAndGoalDraft \
  -only-testing:FoldLogUITests/FoldLogUITests/testSettingsSplitLayoutAndRotation \
  -resultBundlePath artifacts/LocalDuoValidation.xcresult test
```

普通小屏只跑适用场景，如 `testAdaptiveNavigationAndGoalDraft`；`testSettingsSplitLayoutAndRotation` 要求宽屏 Duo。`testUnsupportedPhoneCannotEnterApp` 则要求非 Duo。不要不区分设备条件运行所有 UI 测试并将预期不匹配当成产品回归。

UI 测试的 `--reset-data` 仅与 `--ui-testing` 共同用于独立档案；不通过卸载或手动删除普通目录重置测试。

## 已知诊断与自动化注意事项

- 目标开关仍会触发既存的 SwiftUI `Invalid frame dimension (negative or non-finite).` 运行时警告。iOS 26.5 和 27.1 均可复现，上述相关流程通过且未见对应的可见裁切，但根因尚未解决。不要写成“无警告验收”。
- Duo 纵向 Tab 在 XCTest 中暴露为工具栏 Button，不一定属于 `app.tabBars`。当前测试按 `app.buttons["今日" / "历史" / "设置"]` 查询。
- iOS 27 原生返回按钮曾出现 AX 的 Other / Button 类型不一致；不要为修复测试定位而更换原生导航控件。
- 原生 Form 的开关 identifier 可能指整行；新的 `enableGoal()` 用固定尾部内缩定位实际开关，避免宽屏与小屏按比例点击越界。
- Duo 旋转后 AX 的 App frame 可能保留旧尺寸，内屏窗口也可能仍然较宽；判断以实际可用空间和控件 frame 为准，不能将 portrait 等同于窄屏。
- XCTest 有时截到未激活外屏或黑帧。`scripts/capture-ui-validation.py` 可在测试截图标记处调用 simctl 获取当前实际屏幕。
- 根视图注入的 `--large-text` 没有传入 Sheet。真实目标表单的最大辅助字号已另用模拟器系统设置检查，截图为 `duo-goal-system-largest-text*.png`。复测时可用 `xcrun simctl ui <UUID> content_size` 查询并设置字号，完成后恢复原值。
- 测试失败后的 `simctl diagnose` 曾停滞。只在确认测试已结束后处理对应子进程，不终止其他聊天、Xcode 构建或无关模拟器进程。
- 现有暖白图标是第四轮设计；早期黑底与“折页刻度”仅为历史素材。不要因读取旧文档或重跑生成脚本无意恢复旧图标。

## 能力边界与未完成的发布准备

- 设备模式目前仅处理 App 前台收到并保存的有效铰链事件。真实硬件开合、合拢瞬间事件、内外屏场景交接、后台 / 锁屏 / 退出后返回与采集覆盖均未完成真机验证。
- WidgetKit 展示已保存的统计，不独立采集。保存后请求刷新；实际刷新受系统调度，不能承诺每次开合立即更新。午夜时间线按档案时区预生成，不能补齐未记录的动作。
- 原始“跨其他 App 常驻的系统右侧统计栏”没有找到公开实现接口，已移出体验版范围；当前 App 内纵向导航不等于已实现这个全局栏。没有实时活动实现。
- 没有账号、云同步、广告、内购、JSON 导入或正式商店发布。不要从产品愿景或文案草案推定这些能力已存在。
- Apple 审核指南 2.1(a) 要求提交前进行设备上的缺陷与稳定性测试；通常没有统一的真机测试报告上传步骤。模拟器通过不替代真机验证。
- 真机发布仍需核验型号变体、App Store 的 Duo 下载筛选方式、正式标识及签名、隐私清单、政策与支持页、真实截图与审核材料。当前只限制运行入口，不能声称普通 iPhone 已无法下载。
- 仓库已有 App Store 资料草案；其中有旧图标、旧组件范围等过时表述。若继续准备上架，应先与当前源码、本文件及最新验证记录对齐，再使用文案。资料中记载的其他对话决定需按相应用户任务接续，不作为本次交接中新获授权。

## 文档阅读顺序与 Git 约定

1. 本文件、README：当前实现和运行入口。
2. [UI 视觉规范](UI视觉规范.md)、[计数规则](计数与姿态展示规则.md)、[组件说明](桌面与锁屏小组件.md)、[兼容范围](仅Duo兼容范围.md)：按当前任务选读。
3. [验证记录](../artifacts/validation.md)：先读顶部当前版本，再查相关历史。
4. [产品规划](折叠计数App-产品规划.md)、[系统栏研究](纵向工具栏方案.md)、App Store 草案：包含历史设计和待确认项，不应覆盖较新的用户决定与源码事实。

远端 origin 为 `https://github.com/chenwxiong/FoldLog.git`。首次发布已推送 main；新工作按任务需要使用 `codex/` 前缀分支，不重写已有远端历史。保持构建目录和完整结果包忽略规则，提交前检查文件范围，勿提交密钥、真实个人数据或凭据。

原机器曾因命令行未使用系统代理而出现 GitHub TLS 失败，`gh auth status` 也误报登录无效；在沿用系统代理后认证和推送均成功。其他机器遇到相同症状时，先核对网络及代理，再判断是否需要重新登录，不照抄原机器代理地址。

