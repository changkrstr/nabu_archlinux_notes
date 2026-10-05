# 远程桌面与图形流传输

小米平板 5 具备 2.5K 分辨率屏幕，既可以作为被控端（将平板桌面投射到电脑大屏操作），也可以作为串流客户端（Moonlight 串流电脑显卡游戏）。本节介绍 `krdp` 与 `Sunshine + Moonlight` 两种主流方案。

---

## 方案一：KRDP（KDE 原生 RDP 服务）

`krdp` 是 KDE 官方推出的 Wayland 原生 RDP 服务端，集成度高且资源占用低。

### 1. 安装软件包

```bash
sudo pacman -S krdp
```

### 2. 启用与系统设置

1. 打开 **系统设置** -> 搜索 **远程桌面 (Remote Desktop)**。
2. 启用 RDP 服务，配置登录用户名、密码及端口（默认 3389）。

### 3. Windows 客户端连接踩坑指南

在 Windows 电脑上使用系统自带的“远程桌面连接”（`mstsc.exe`）连入平板时，注意以下两项关键配置：

- **无法弹出密码框排查**：连接时**必须勾选“允许我保存这些凭据”**，点击连接后才会弹出输入用户密码的对话框；如果不勾选，Windows RDP 会直接报错连接失败。
- **高分屏自动缩放（Smart Sizing）**：
  由于平板是 2560x1600 高清分辨率，直接 RDP 窗口可能导致界面过大或滚动条过长。
  1. 在 Windows 远程桌面连接界面中点击“另存为”，保存一个 `.rdp` 配置文件。
  2. 使用记事本或文本编辑器打开该 `.rdp` 文件，在最末尾追加一行：
     ```text
     smart sizing:i:1
     ```
  3. 双击该配置文件连接，窗口将自动按比例智能缩放适应当前电脑屏幕。

---

## 方案二：Sunshine + Moonlight（低延迟图形与游戏串流）

Sunshine 是一款高性能的开源 GameStream/Moonlight 串流服务端，支持硬件编码与超低延迟图形传输。

### 1. Sunshine 服务端安装（aarch64）

> 📌 **源说明**：Sunshine 官方的 Arch pacman 仓库暂未提供 `aarch64` 预编译包。因此在 ARM64 平板上推荐使用 AppImage 或 Flatpak。

#### 方法 A：AppImage 运行（推荐）

从 [Sunshine GitHub Releases](https://github.com/LizardByte/Sunshine/releases) 下载 aarch64 架构的 `.AppImage` 文件：

```bash
chmod +x sunshine.AppImage
./sunshine.AppImage
```

#### 方法 B：Flatpak 安装

```bash
# 添加 Flathub 镜像源
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 安装 Sunshine
flatpak install flathub dev.lizardbyte.app.Sunshine

# 运行 Sunshine
flatpak run dev.lizardbyte.app.Sunshine
```

启动后，访问提示的 Web 管理后台（默认 `https://localhost:47990`），设定账号密码并进行配对。

### 2. Moonlight 客户端安装

如果需要将小米平板 5 作为串流副屏（接收电脑端显卡游戏串流），直接安装官方 `moonlight-qt`：

```bash
sudo pacman -S moonlight-qt
```

打开 Moonlight 后会自动发现局域网/Tailscale 中的游戏主机，输入 PIN 码即可开启极低延迟游戏与桌面串流。

---

## 下一步

配置好远程图形显示后，继续配置开发与容器环境：[Docker 安装与 iptables 避坑修复](./02-docker.md)。
