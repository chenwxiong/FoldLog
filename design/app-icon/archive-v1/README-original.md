# 折记 · App Icon 首轮设计

2026-10-24。iPhone Duo 专属开合计数 App，工作名称仍可调整。图形不包含产品名称，后续改名无需重画图标。

![三稿对比](icon-directions.png)

| 方向 | 含义 | 当前状态 |
| --- | --- | --- |
| A · 折页刻度 | 两片折面表示开合，一侧三道刻度表示记录 | 推荐；已接入体验版主图标 |
| B · 回折 | 白金几何纸带形成翻折转向 | 备选；未接入主图标 |
| C · 折记 | 三道记号与一笔折线结合 | 备选；未接入主图标 |

各目录提供 `default`、`dark`、`tinted` 的 PNG 和 SVG。着色文件为灰阶基底，系统着色后实际颜色由用户设置决定。`previous-icon.png` 保留上一轮的双片图标。

## 交付规格

- 1024 × 1024，sRGB；主图标 PNG 无透明通道，四角保持方形，圆角由系统裁切。
- 默认底色 `#101114`，暖白 `#F5F2EA`，金色 `#D6B675`。深色版本降低前景亮度；着色版本使用灰阶层级。
- 原创几何路径，无 SF Symbols、Apple 硬件轮廓、数字徽标、文字或烘焙的玻璃高光与阴影。
- 对比图中的圆角仅用于预览；已检查 60、40、29pt 三种尺寸的视觉识别。
- A 另提供透明的 `layer-white.svg`、`layer-gold.svg`，可作为 Icon Composer 的前景分层输入。当前工程接入的是资产目录中的默认 / 深色 / 着色 PNG，尚未制作为 `.icon` 分层文件；透明和 Liquid Glass 呈现待在 iOS 27.1 环境复查。

图形源定义与导出脚本为 `scripts/make-icon.swift`，在项目根目录运行 `swift scripts/make-icon.swift` 可重建素材与对比图。SVG 与 PNG 使用同一组路径数据。当前三稿均为代码绘制的原创矢量设计，没有使用图片生成模型。

已安装到普通 iPhone 模拟器进行开发预览，[主屏实际截图](home-screen-preview.png) 确认系统裁切后显示新的 A 图标；该检查不代表对普通 iPhone 的产品支持。

遵循 Apple HIG 的 App icons、SF Symbols 指南：界面内使用 SF Symbols；桌面品牌图标采用原创图形。
