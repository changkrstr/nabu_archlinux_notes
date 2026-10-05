# 内核更新与 RootFS 离线定制实战

对于进阶 Linux 玩家与嵌入式开发者，自行定制编译内核以及离线定制纯净、开箱即用的 RootFS 是深度掌控设备体验的关键技能。

本文档包含两部分核心内容：
1. **内核更新实测与电量异常自愈说明**；
2. **基于 Docker 跨架构深度定制 RootFS 实战指南（经实机侧载验证）**。

---

## 1. 内核更新实测与电量异常说明

在早期使用过程中，偶尔会遇到开机进入桌面后**电池电量显示为空、无法识别充电状态**的问题：

```bash
# 尝试更新 nabu 专用主线内核与头文件
sudo pacman -Syu linux-nabu linux-nabu-headers
```

> 💡 **实测经验分享**：
> 后来在实际使用中发现，开机偶尔丢失电量读数更可能是启动阶段 PMIC 驱动枚举时序或电池驱动握手偶发超时所致，绝大多数情况下**重启平板即可自愈**，并非必须依赖特定的内核更新。

---

## 2. RootFS 离线深度定制实战指南

### 2.1 为什么需要离线定制 RootFS？

官方安装包默认刷入的是纯英文环境、无浏览器、无中文输入法的初始系统。在触屏平板上，首次开机会陷入“无实体键盘无法便捷敲命令”、“无中文输入法无法搜索”、“海外源拉取软件缓慢超时”的启动困境。

通过在 PC 端（Docker 容器环境）直接对 `rootfs.img` 进行解包与 chroot 预装配置，可以实现**开箱即用（Out of the box）**：
- 默认清华大学 TUNA 镜像源与 Arch Linux CN 软件源；
- 默认简体中文环境（`zh_CN.UTF-8`）与 CJK 字体；
- 预装 Fcitx 5 拼音输入法并预置激活配置；
- 预装原生 ARM64 Firefox 浏览器与中文语言包；
- 默认开启 SSH 远程服务并预生成主机密钥。

---

### 2.2 刷入机制与 Fastboot 踩坑预警（重要）

在尝试将定制的 `rootfs.img` 刷入平板时，必须注意刷入方式的区别：

#### ⚠️ 踩坑记录：`fastboot flash` 内存溢出崩溃
如果尝试在 PC 端直接通过 Fastboot 刷入单个 7GB 镜像：
```bash
fastboot flash linux rootfs.img
# 报错：
# libc++abi: terminating due to uncaught exception of type std::bad_alloc: std::bad_alloc
```
- **根因分析**：Windows / PC 端 fastboot 工具在执行 `flash` 时，会试图将整个 7GB 裸 ext4 镜像一次性 `malloc` 加载到宿主机连续内存缓冲区。超大连续内存分配极易耗尽地址空间，引发 `std::bad_alloc` 内存溢出崩溃。
- **机制对比**：
  - **Fastboot 直接刷**：适合 Android 专用的稀疏切片镜像（Sparse image），不适合直接刷单体 Raw ext4 镜像。
  - **TWRP 侧载（Sideload，推荐）**：卡刷包内部使用流式管道解压：
    ```bash
    7zzs e -so "$ZIPFILE" "images/rootfs.img" > "$linux_part"
    ```
    边流式解压边写入 Linux 物理分区，PC 端仅传输约 2.4GB 的压缩包，平板端仅需维持几兆的解压缓冲区，零内存溢出风险，速度快且极稳定！

---

### 2.3 跨架构定制环境准备（Docker + binfmt）

由于平板为 ARM64（`aarch64`）架构，而 PC 通常为 x86_64 架构，我们需要借助 QEMU 用户态仿真与 Docker 容器实现跨架构透明运行。

#### 1. 注册 ARM64 binfmt 解释器
在 PC 宿主机（WSL2 / Linux / Windows Docker）终端执行：
```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

#### 2. 解压并扩容原始 rootfs.img
从官方安装包 `arch-nabu-installer-plasma.zip` 中提取出 `images/rootfs.img`：
```bash
7z e arch-nabu-installer-plasma.zip images/rootfs.img -ocustom/images
```
原始镜像大约 6.15 GB，可用空间仅剩约 400 MB，无法容纳大型应用（如 Firefox、CJK 字体等）。在定制前必须给 ext4 镜像安全扩容：
```bash
# 进入容器扩容 3GB
truncate -s +3G custom/images/rootfs.img
e2fsck -f -y custom/images/rootfs.img
resize2fs custom/images/rootfs.img
```

---

### 2.4 核心定制步骤与排坑细节

使用 Debian / Ubuntu / Arch 容器以 `--privileged` 方式挂载运行定制脚本：

```bash
docker run --rm --privileged \
  -v "C:/path/to/archlinux/custom:/work" \
  debian:bookworm /bin/bash /work/customize-rootfs.sh
```

核心定制流程主要包含以下关键技术点：

#### 1. 虚拟文件系统挂载与 DNS 避坑
- 必须 bind 挂载 `/dev`, `/dev/pts`, `/proc`, `/sys`；
- **DNS 避坑**：Arch Linux 的 `/etc/resolv.conf` 往往是指向 `/run/systemd/resolve/resolv.conf` 的软链接。在挂载状态下若未创建目标目录，直接写入会导致报错。需预先创建 `/run/systemd/resolve/` 并写入公共 DNS：
  ```bash
  mkdir -p /mnt/rootfs/run/systemd/resolve
  cat << 'EOF' > /mnt/rootfs/run/systemd/resolve/resolv.conf
  nameserver 223.5.5.5
  nameserver 119.29.29.29
  EOF
  ```

#### 2. 软件源与网络代理策略
- **清华镜像源**：在 `/etc/pacman.d/mirrorlist` 顶端配置清华镜像；
- **Arch Linux CN 源**：在 `/etc/pacman.conf` 中追加清华 `[archlinuxcn]` 源；
- **密钥环信任冷启动**：初次安装 `archlinuxcn-keyring` 时，可先将 `[archlinuxcn]` 设置为 `SigLevel = Optional TrustAll`，安装好密钥环后恢复默认签名验证；
- **网络路由优化**：国内清华源直连（几秒即可同步完毕），外网域名（如 GitHub Releases）如遇缓慢，可通过环境变量指向宿主机代理端口（如 `http://host.docker.internal:7897`）。

#### 3. 语言环境与中文字体
```bash
# 生成中文 locale
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf

# 安装中文字体（解决豆腐块方块字）
pacman -S --noconfirm --needed noto-fonts-cjk wqy-zenhei
```

同时在 `/home/user/.config/plasma-localerc` 中配置 KDE 桌面环境语言：
```ini
[Formats]
LANG=zh_CN.UTF-8

[Translations]
LANGUAGE=zh_CN:en_US
```

#### 4. Fcitx 5 输入法与 Wayland 规范避坑（高危）
- **安装软件包**：
  ```bash
  pacman -S --noconfirm --needed fcitx5 fcitx5-chinese-addons fcitx5-configtool fcitx5-qt fcitx5-gtk
  ```
- **⚠️ 环境变量规范避坑**：
  在现代 **Wayland / KDE Plasma** 环境下，原生应用直接通过 Wayland 的 `text-input` 协议与输入法通信。**绝对不能**在 `/etc/environment` 中设置 `GTK_IM_MODULE=fcitx` 或 `QT_IM_MODULE=fcitx`，否则会导致 Firefox、Chromium 等应用在 Wayland 下崩溃或无法调起软键盘！
  正确的环境变量应为：
  ```bash
  XMODIFIERS=@im=fcitx
  SDL_IM_MODULE=fcitx
  GLFW_IM_MODULE=fcitx
  ```
- **预置拼音配置（开箱即用）**：
  写入 `/home/user/.config/fcitx5/profile`，开机默认激活美式键盘与拼音输入法，无需进入系统设置手动添加：
  ```ini
  [Groups/0]
  Name=Default
  Default Layout=us
  DefaultIM=pinyin

  [Groups/0/Items/0]
  Name=keyboard-us
  Layout=

  [Groups/0/Items/1]
  Name=pinyin
  Layout=

  [GroupOrder]
  0=Default
  ```

#### 5. 原生 Firefox 浏览器
```bash
pacman -S --noconfirm --needed firefox firefox-i18n-zh-cn
# 并在 /home/user/Desktop/firefox.desktop 创建桌面启动图标
```

#### 6. 开启 SSHD 开机自启
为了在开机后能立即通过局域网或 USB 网络连接平板：
```bash
systemctl enable sshd.service
# 预先生成主机密钥，避免开机首次握手延迟
ssh-keygen -A
```

---

### 2.5 镜像瘦身与重新打包

完成软件包定制后，需要对镜像进行瘦身和标准化收缩，以保证卡刷包体积紧凑：

1. **清理缓存**：
   ```bash
   chroot /mnt/rootfs pacman -Scc --noconfirm
   rm -rf /mnt/rootfs/var/cache/pacman/pkg/*
   ```
2. **精确收缩文件系统**：
   实际安装完软件后占用约 5.9 GB。使用 `resize2fs` 将文件系统收缩到 7200 MB 并截断镜像末尾：
   ```bash
   e2fsck -f -y custom/images/rootfs.img
   resize2fs custom/images/rootfs.img 7200M
   truncate -s 7549747200 custom/images/rootfs.img
   e2fsck -f -y custom/images/rootfs.img
   ```
3. **空闲块填零（Zero-fill）**：
   将所有未分配的数据块填零，使 7z 压缩率最大化：
   ```bash
   mount custom/images/rootfs.img /mnt/rootfs
   dd if=/dev/zero of=/mnt/rootfs/zero.tmp bs=4M || true
   rm -f /mnt/rootfs/zero.tmp
   umount /mnt/rootfs
   ```
4. **重新打包卡刷包**：
   使用 7-Zip 将更新后的 `images/rootfs.img` 替换进卡刷安装包：
   ```bash
   cd custom && 7z u ../arch-nabu-installer-plasma-custom.zip images/rootfs.img
   ```
   打包后的 ZIP 文件仅约 **2.4 GB**，比原版仅增加 200 MB 左右，但内建了完备的中文与生产力套件。

---

### 2.6 配套脚本清单

本项目在 `notes/scripts/` 中提供了完整的自动化脚本供直接复用：
- `notes/scripts/customize-rootfs.sh`：容器内自动化定制全流程执行脚本；
- `notes/scripts/verify-rootfs.sh`：镜像挂载与功能项全面自动化验证脚本。

---

## 3. 返回目录

回到全局导航：[返回文档首页目录](../../README.md)。
