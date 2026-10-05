# 前言与准备工作

本指南适用于小米平板 5（代号：`nabu`）安装并配置 Arch Linux ARM + KDE Plasma 桌面环境。

---

## 1. 必要准备

在开始刷机与安装之前，请准备好以下工具和资源：

- **RootFS 镜像与 UEFI**：
  - [GitHub 仓库: Nabu Arch (Kumar-Jy/Nabu-arch-images)](https://github.com/Kumar-Jy/Nabu-arch-images)
- **推荐的 TWRP Recovery**：
  - `V4-TWRP-NABU-10-05.img`：[TWRP 下载地址 (GitHub Releases)](https://github.com/Kumar-Jy/twrp_device_xiaomi_nabu/releases/tag/mod-hybrid)
- **电脑端环境**：
  - 一台配置好 `adb` 和 `fastboot` 驱动及命令行工具的电脑（Windows / Linux / macOS 均可）
  - 一根稳定的 USB Type-C 数据线

---

## 2. 准备注意事项与经验说明

> 💡 上述两个仓库基本是开箱即用的，整体安装流程非常清晰简单。

- **TWRP 版本选择**：
  - 发布的 Release 中有一个文件名带有 `HYBRID` 的版本，如果普通版本启动卡住或启动不了，请尝试下载该 `HYBRID` 版本。
- **Boot 引导排查**：
  - 如果 TWRP 无法正常引导启动，也有可能是当前系统的 boot 分区原因，可以尝试先刷入一个第三方 boot 镜像后再尝试启动 TWRP。

---

## 3. 下一步

环境与工具准备完毕后，请阅读下一步：[磁盘分区（多系统）](./02-partitioning.md)。
