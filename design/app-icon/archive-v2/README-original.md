# 折记 · App Icon 材质迭代

2026-10-24。当前主图标为第二轮「折光」：珍珠白正面翻向香槟金背面，搭配石墨黑底。工作名称可调整，图形不含文字。

![第二轮材质与外观对比](v2-fold-light/icon-review.png)

## 本轮设计

- **折光（当前主图标）**：用连续翻折的白金折带表达开合。收圆轮廓，移除旧版的刻度细槽，强化整体识别。
- **对页（备选）**：珍珠白与香槟金两片折面交叠，更直观地表达展开；未接入 App。
- 参考用户附图的柔和渐变、材质层次和圆润边缘，绘制原创路径；未使用参考图中的标志或 SF Symbols。
- SVG 中的宽幅色彩渐变表现折面朝向。边缘高光、玻璃效果与层间阴影交给 Icon Composer / iOS 生成，避免在每层叠加烘焙阴影。

## 工程与素材

| 文件 | 用途 |
| --- | --- |
| `../../FoldLog/FoldLogIcon.icon/` | **Xcode 当前使用的原生分层图标**；前景为两张透明 SVG，背景与系统材质在 `icon.json` 配置 |
| `v2-fold-light/fold-light/` | 主方向的源 SVG、可编辑 `.icon` 以及系统外观预览 |
| `v2-fold-light/fold-wings/` | 「对页」备选，同样提供源 SVG 与 `.icon` |
| `v2-fold-light/icon-review.png` | 两个方向、新旧对照、60 / 40 / 29pt 缩小及外观预览 |
| `v2-fold-light/duo-home-screen.png` | iOS 27.1 / iPhone Duo 外屏主屏的实际截图，已确认新图标 |
| `archive-v1/`、原有 A / B / C 目录 | 第一轮设计与绘制脚本归档，不再是当前接入方案 |

Icon Composer 导出 `default`、`dark`、`tinted`、`clear-light`、`clear-dark` 五种预览；预览带系统圆角与透明外缘，只用于检查，不当作无透明的 App Store 原图。着色和透明外观在实际桌面中的颜色受用户设置与壁纸影响。

原有 `AppIcon.appiconset` 同步保留 1024 × 1024、sRGB、无透明通道、未裁切圆角的静态 PNG；当前构建设置 `ASSETCATALOG_COMPILER_APPICON_NAME = FoldLogIcon`，实际使用 `.icon`。兼容提示页的 `BrandMark` 同步更新为透明的原创标记。

## 重建

在项目根目录运行（Python 3、Swift 与 Xcode 自带的 Icon Composer，无第三方包）：

```sh
python3 scripts/make-icon.py
swift scripts/make-icon.swift
```

前者生成 SVG、原生 `.icon` 与系统外观预览；后者生成静态备用资源、BrandMark 和对比图。修改构建配置后可运行 `python3 scripts/generate-project.py` 重建 Xcode 工程。第一轮脚本归档仅供历史参考，运行会恢复旧版资产，勿用于当前素材重建。

本轮已通过 Duo 模拟器构建、安装与外屏主屏检查。模拟器不能替代真实设备上的动态光照体验。
