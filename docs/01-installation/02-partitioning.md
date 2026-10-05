# 磁盘分区（多系统）

为了在小米平板 5（nabu）上运行 Arch Linux，同时保留或支持 Android 双系统/多系统共存，需要对存储空间进行重新分区。

---

## 1. 数据备份警告

> ⚠️ **高危操作提示**：
> 分区操作**会格式化平板的 `userdata` 分区**！
> 在操作前，请务必完整备份平板上的 Android 数据、照片、重要文件。

---

## 2. 引导至 TWRP Recovery

1. 将平板重启进入 **Bootloader (Fastboot)** 模式（关机状态下长按 `电源键 + 音量下键`）。
2. 将平板通过 USB 数据线连接到电脑。
3. 在电脑终端中执行以下命令，临时启动至 TWRP：

```bash
fastboot boot path/to/twrp.img
```

> 📌 **提示**：即使 TWRP 一直卡在启动 Splash 界面也没关系，只要底层的 `adbd` 已经成功运行即可继续下一步。

---

## 3. 执行交互式分区脚本

在电脑终端中进入 `adb shell`：

```bash
adb shell
```

在设备的 shell 环境中执行分区脚本：

```bash
# in adb shell
partition
```

该分区脚本是全交互式的，按照终端屏幕上的提示依次选择分配给 Android 和 Linux 的空间大小即可。

> 💡 如果你使用的是其他版本的 TWRP 或自制 Recovery，分区命令或脚本可能略有不同，具体可参考对应工具的发布说明。

---

## 4. 下一步

分区完成后，继续进入系统的刷入环节：[系统刷入](./03-flashing.md)。
