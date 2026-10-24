# 仅支持 iPhone Duo

2026-10-24，用户明确限定支持 iPhone Duo。普通 App 指应用形态，不再表示支持普通 iPhone。

## 当前实现

- 发布构建：iOS 27.1 及以上，iPhone 设备族；关闭 Mac Catalyst、Mac 与 Apple Vision 的 Designed for iPhone/iPad 兼容入口。
- 运行入口：仅已知的 Duo 型号且满足系统版本时进入主界面。其他设备显示“仅支持 iPhone Duo”，没有进入计数功能的按钮。
- 型号白名单：`iPhone19,4`，来源为本机 Xcode 27.1 的 `iPhone Duo.simdevicetype/Contents/Resources/profile.plist`，其 `modelIdentifier` 和 `representedModelIdentifiers` 一致。该来源为开发工具的设备配置，发布前仍须用实际 Duo 核验并确认区域变体。
- 真机通过公开 POSIX `uname` 读取硬件标识；模拟器读取 `SIMULATOR_MODEL_IDENTIFIER`。不使用设备名称、屏幕尺寸或“本次没有铰链回调”推断机型。
- 首次在受支持设备运行默认使用设备记录；已有记录模式与档案继续保留，演示记录仍与设备记录隔离。

型号限制只控制应用入口，不是 App Store 下载过滤的证明。当前没有写入未经核实的 `UIRequiredDeviceCapabilities` 值；Apple 官方能力清单页面本轮连接失败。上架前需核验商店的设备筛选机制，不能把仅声明 iPhone 设备族理解为只允许 Duo 下载。

## 开发预览

在没有 Duo 运行时的环境中，也可以使用普通模拟器设计 UI：

1. Debug 构建保留 iOS 26+ 编译兼容性，Xcode 调试参数添加 `--design-preview` 可在普通 iPhone 模拟器预览。
2. `scripts/run-preview.command` 已自动传入这个参数。
3. `--ui-testing` 同样仅在 Debug 模拟器中允许界面测试；加入 `--check-device-support` 后恢复真实兼容检查，用于验证拦截页面。
4. 真机和 Release 不接受以上参数作为机型限制的绕过方式。Release 最低系统版本为 iOS 27.1。

开发预览不扩大对外支持范围。宽度自适应继续用于 Duo 的内外屏与窗口空间，普通机型横屏只是布局预览。真实 Duo 的内外屏切换、持续采集及后台能力仍待实际环境验证。

实现见 `DeviceSupport.swift`、`Core/DeviceSupportPolicy.swift`；策略测试涵盖非 Duo、非手机、低系统版本和未来系统版本。
