# 系统维护与备份思考

> 本文由AI整理，我还没有验证！！静待后续更新

在嵌入式与移动 ARM64 设备上折腾 Linux，系统崩溃或误操作的风险远高于常规 x86 PC，因此做好系统与分区级别的备份恢复至关重要。

---

## 1. 备份策略探讨

### 1.1 分区镜像级备份（DD 镜像法）

在 TWRP Recovery 或其他 Linux 临时环境（通过 USB 连接电脑执行 adb shell）中，可以直接对整个 Linux rootfs 分区进行块级镜像备份：

```bash
# 示例：通过 adb 管道直接流式备份分区到电脑本地
adb exec-out "dd if=/dev/block/by-name/linux bs=4M status=progress" > nabu_linux_backup.img
```

- **优点**：100% 完整无损还原，包含分区表、文件系统元数据与所有权限。
- **缺点**：生成的镜像体积等同于分配的分区物理大小，占用空间较多。

### 1.2 文件系统级归档备份（Tar / Rsync 法）

在系统正常运行或挂载在 Recovery 状态下，使用 `tar` 打包排除临时目录：

```bash
sudo tar --exclude='/proc/*' \
         --exclude='/sys/*' \
         --exclude='/dev/*' \
         --exclude='/tmp/*' \
         --exclude='/run/*' \
         --exclude='/mnt/*' \
         --exclude='/lost+found' \
         -cvpzf /mnt/external_sd/arch_backup.tar.gz /
```

- **优点**：仅打包实际使用的空间，压缩率高。
- **还原要点**：恢复时需要重新格式化分区，解压后注意检查 `/etc/fstab` 中的 UUID 是否匹配。

---

## 2. 系统异常自愈与急救建议

- **SSH / 物理键盘备用**：当触控屏或图形界面因配置崩溃无法输入时，优先通过外接 USB Type-C 扩展坞连接实体键盘，或者使用 USB 有线网络 SSH 连入排查。
- **保持双系统 Recovery 可用**：永远保留一份能正常工作的 TWRP 或第三方 Boot 分区，以便随时可以通过 Recovery 侧载重刷或进入终端急救。

---

## 3. 下一步

查看进阶探索篇：[内核与 RootFS 自构建探索](./02-kernel-and-rootfs.md)。
