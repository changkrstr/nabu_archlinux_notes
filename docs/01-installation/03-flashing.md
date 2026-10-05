# 刷入系统

完成磁盘分区后，即可将 Arch Linux 的 Installer 刷机包安装到小米平板 5（nabu）中。

---

## 1. 刷入 Installer 安装包

刷入方式通常有两种：
1. **Push 到存储卡刷入**：将安装包推送到 `/sdcard/` 并在 Recovery 界面中选择 Install。
2. **ADB 侧载刷入（Sideload，推荐）**：直接通过 ADB 命令行侧载。

---

## 2. 常见问题排查：TWRP 无法侧载/卡死

如果尝试启动的 TWRP 始终卡在开机启动画面，无法进入图形界面、无法 `adb push` 且无法直接执行 `adb sideload`：

> 💡 **实测可行方案**：
> 可以先刷入一个任意第三方 ROM 的 `boot` 镜像（例如 crDroid 的 boot），重启引导至该第三方 ROM 自带的 Recovery 界面，然后再执行侧载。

---

## 3. 执行侧载刷入

在 Recovery 侧载模式下，在电脑端终端执行：

```bash
adb sideload path/to/arch-nabu-installer-plasma.zip
```

等待终端进度条走完并提示完成。

---

## 4. 首次引导进入 Arch Linux

1. 侧载完成后重启平板。
2. 屏幕将进入 UEFI / 多系统选择界面（Dual Boot Menu）。
3. 使用 **音量加 / 减键** 切换启动选项，选中 Arch Linux 项后按下 **电源键** 确认。
4. 随后屏幕将加载内核并进入 Arch Linux（KDE Plasma 桌面）。

---

## 5. 下一步

系统成功启动后，进入基础环境配置：[系统基础配置 - 软件包管理](../02-basic-setup/01-package-manager.md)。
