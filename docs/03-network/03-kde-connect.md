# KDE Connect 多设备协同

KDE Connect 是 KDE 桌面生态下最强大的跨设备协同工具，能够实现 Android/Windows/Linux 之间的双向剪贴板同步、文件隔空投送、通知互通以及媒体播放控制。

---

## 1. 安装软件包

```bash
sudo pacman -S kdeconnect
```

安装后可在 KDE 应用菜单中找到 **KDE Connect**，或者在系统设置的设备列表中进行配对。

---

## 2. 配合 Tailscale 跨网段/跨公网联动（核心技巧）

默认情况下，KDE Connect 依赖本地局域网的 UDP 广播进行设备发现。如果平板与电脑处于不同局域网（例如平板挂在手机热点，电脑在公司 Wi-Fi），单纯依赖广播无法发现彼此。

虽然移动端 App 支持手动输入 IP，但桌面端界面没有显式的“添加 IP”按钮，需要手动修改配置文件。

### 2.1 配置文件路径

- **Linux（平板端）**：`~/.config/kdeconnect/config`
- **Windows（电脑端）**：`%LOCALAPPDATA%\kdeconnect\config`

### 2.2 添加自定义节点 IP

打开对应的 `config` 文件，在配置组中添加或修改 `customDevices` 字段，填入对方的 Tailscale IP（多个 IP 用英文逗号分隔）：

```ini
customDevices=100.64.0.2,100.64.0.3
```

保存文件后，重启 KDE Connect 进程或注销重新登录。两端即可通过 Tailscale 隧道无缝握手配对。

---

## 3. 下一步

网络连接打通后，进入桌面应用与远程显示配置：[远程桌面配置 (krdp 与 Sunshine + Moonlight)](../04-apps-and-services/01-remote-desktop.md)。
