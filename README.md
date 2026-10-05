# 小米平板 5 (nabu) Arch Linux 折腾与配置笔记

本项目是针对小米平板 5（代号：`nabu`）刷入并运行 **Arch Linux ARM + KDE Plasma 桌面** 的项目级多文件知识库与踩坑实录。

`README.md` 仅作为全局目录与导航索引，详细内容请点击下方各个模块文档查阅。

---

## 📑 目录索引

### 1. 安装与引导 (Installation)

- [1.1 前言与准备工作](docs/01-installation/01-prerequisites.md)：硬件准备、镜像与 UEFI 资源、TWRP 下载及引导排坑
- [1.2 磁盘分区（多系统）](docs/01-installation/02-partitioning.md)：Android 与 Linux 双系统重新分区、交互式分区脚本
- [1.3 刷入系统与首次引导](docs/01-installation/03-flashing.md)：Installer 刷机包侧载（Sideload）、第三方 Recovery 避坑、UEFI 菜单启动

### 2. 系统基础配置 (Basic Setup)

- [2.1 软件包管理与源配置](docs/02-basic-setup/01-package-manager.md)：清华 pacman 镜像源、archlinuxcn 软件源与 GPG 密钥、全系统更新、paru (AUR 助手) 构建
- [2.2 用户与基础服务配置](docs/02-basic-setup/02-user-and-ssh.md)：sudo 免密配置、开机自启 sshd 远程服务、tmux 会话保持与鼠标支持、mandoc 手册工具
- [2.3 中文与输入环境配置](docs/02-basic-setup/03-locale-and-input.md)：Noto 中文字体、Locale 生成、Fcitx 5 拼音输入法、会话环境变量自启、虚拟键盘选型（OSKB vs Plasma vs Fcitx 5）
- [2.4 电源管理与休眠配置](docs/02-basic-setup/04-power-management.md)：挂起恢复黑屏死锁深度避坑（锁屏+息屏策略）、TLP 电源套件安装与 rfkill 冲突解决

### 3. 网络与互联 (Networking & Connectivity)

- [3.1 USB 调试与 RNDIS 有线网络](docs/03-network/01-usb-gadget-network.md)：UDC (`a600000.usb`) 原理、ConfigFS 设备绑定、Windows RNDIS 驱动修复、Systemd 开机自动化服务
- [3.2 Tailscale 异地虚拟局域网](docs/03-network/02-tailscale.md)：跨公网 P2P 穿透组网、服务自启与免公网 IP 随时 SSH 远程
- [3.3 KDE Connect 多设备协同](docs/03-network/03-kde-connect.md)：跨网段配对痛点、通过配置文件注入 Tailscale IP 实现跨公网剪贴板与通知同步

### 4. 桌面应用与开发生态 (Apps & Services)

- [4.1 远程桌面与图形流传输](docs/04-apps-and-services/01-remote-desktop.md)：KRDP (Wayland 原生 RDP) 配置与 Windows 客户端高分屏智能缩放（Smart Sizing）、Sunshine + Moonlight 游戏与低延迟串流
- [4.2 Docker 容器环境与 iptables 修复](docs/04-apps-and-services/02-docker.md)：Docker 服务配置、`iptables-nft` 缺失 `CONFIG_NFT_COMPAT` 报错深度排查、切换 `iptables-legacy` 完美解决
- [4.3 Steam 与 x86 转译器 (FEX-Emu)](docs/04-apps-and-services/03-steam-and-fex.md)：ARM64 运行 PC 游戏全链路、自行源码编译 FEX-Emu、Ubuntu 24.04 RootFS 挂载、Steam deb 提取部署、Distrobox 踩坑实录
- [4.4 AI Coding Agent 环境搭建](docs/04-apps-and-services/04-ai-agent.md)：Node.js 运行时安装、npm 全局路径迁移免 root 提权、终端 Coding Agent 部署
- [4.5 日常桌面软件与美化](docs/04-apps-and-services/05-desktop-apps.md)：Firefox 原生 ARM64 触控体验、科学上网代理工具生态、KDE Plasma 触控与美化心得

### 5. 系统维护与进阶探索 (Advanced)

- [5.1 系统维护与备份思考](docs/05-advanced/01-maintenance.md)：DD 块级分区镜像备份、Tar / Rsync 文件级备份、系统异常急救原则
- [5.2 内核更新与 RootFS 离线定制实战](docs/05-advanced/02-kernel-and-rootfs.md)：`linux-nabu` 内核更新体验、电量异常自愈经验、基于 Docker 的跨架构 RootFS 离线定制全流程实战（中文/输入法/Firefox/清华源/archlinuxcn/sshd/Fastboot 与 TWRP 机制对比）

---

## 📂 项目结构树

```text
.
├── README.md                           # 全局目录索引与导航入口
├── docs/                               # 核心技术文档库
│   ├── 01-installation/                # 1. 安装与引导
│   │   ├── 01-prerequisites.md         # 前言与准备工作
│   │   ├── 02-partitioning.md          # 磁盘分区（多系统）
│   │   └── 03-flashing.md              # 刷入系统与 Recovery 侧载
│   ├── 02-basic-setup/                 # 2. 系统基础配置
│   │   ├── 01-package-manager.md       # pacman / archlinuxcn / paru 源配置
│   │   ├── 02-user-and-ssh.md          # sudo 免密、sshd、tmux、mandoc
│   │   ├── 03-locale-and-input.md      # 中文字体、输入法与虚拟键盘对比
│   │   └── 04-power-management.md      # 挂起避坑与 TLP 电源管理
│   ├── 03-network/                     # 3. 网络与互联
│   │   ├── 01-usb-gadget-network.md    # USB RNDIS 有线网卡 (UDC/ConfigFS/Systemd)
│   │   ├── 02-tailscale.md             # Tailscale 异地组网
│   │   └── 03-kde-connect.md           # KDE Connect 跨网络协同
│   ├── 04-apps-and-services/           # 4. 桌面应用与开发生态
│   │   ├── 01-remote-desktop.md        # KRDP 与 Sunshine + Moonlight
│   │   ├── 02-docker.md                # Docker 与 iptables-legacy 兼容性修复
│   │   ├── 03-steam-and-fex.md         # FEX-Emu 编译与 Steam 游戏环境
│   │   ├── 04-ai-agent.md              # Node.js 与 AI Agent
│   │   └── 05-desktop-apps.md          # Firefox、代理客户端与 KDE 美化
│   └── 05-advanced/                    # 5. 系统维护与进阶探索
│       ├── 01-maintenance.md           # 分区备份与急救策略
│       └── 02-kernel-and-rootfs.md     # 内核状态与自构建路线
└── scripts/                            # 配套自动化脚本与系统服务
    ├── usb-net-gadget.sh               # USB RNDIS 自动初始化配置脚本
    ├── usb-net.service                 # USB 网络开机自启 systemd 单元文件
    ├── customize-rootfs.sh             # Docker 跨架构 RootFS 自动化定制脚本
    └── verify-rootfs.sh                # RootFS 定制镜像全面自动化验证脚本
```
