# Steam 与 x86 转译器（FEX-Emu）配置实录

Steam 官方目前并未公开发布针对 `ARM64 (aarch64)` 架构的原生桌面客户端。要在骁龙 860 的平板上玩 PC 游戏，需要借助用户态 x86_64 二进制转译器（如 FEX-Emu / Box64）。

---

## 1. 避坑前言与方案对比

- ❌ **AUR 的 `fex-emu-wine-git`**：并不是我们需要的完整指令转译运行时，无需尝试。
- ❌ **`archlinuxcn` 仓库提供的预编译 `fex-emu`**：在当前 nabu 设备内核下，使用 `FEXRootFSFetcher` 下载 Arch 或 Ubuntu RootFS 后均无法启动，执行 `FEX /usr/bin/uname -a` 直接报**段错误（Segmentation Fault）**。
- ❌ **PostmarketOS Wiki 的 `distrobox --root --init` 方案**：如果附加了 `--root --init` 参数，容器内启动 FEX 会报错提示无法连接 `FEXServer.Socket`。
- ✅ **推荐实测方案：自行源码编译 FEX-Emu**，运行稳定顺畅。

---

## 2. 方案一：自行源码编译 FEX-Emu（推荐，实测完美运行）

官方参考指南：[FEX-Emu Wiki: Setting Up FEX](https://wiki.fex-emu.com/index.php/Development:Setting_up_FEX)

### 2.1 依赖安装与编译前准备

在 Arch Linux ARM（平板系统）中安装必要的编译工具链与依赖库：

```bash
# 1. 安装构建依赖
sudo pacman -S --needed base-devel cmake ninja clang llvm lld \
  pkgconf ccache python-setuptools squashfs-tools squashfuse erofs-utils

# 2. （可选推荐）临时屏蔽系统休眠，防止长耗时编译过程中平板屏幕灭屏挂起导致网络中断
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 3. （可选）配置网络代理以加速 GitHub 子模组拉取（若处于代理局域网）
export http_proxy=http://<PC_IP>:7897
export https_proxy=http://<PC_IP>:7897
export ALL_PROXY=http://<PC_IP>:7897
git config --global http.proxy http://<PC_IP>:7897
git config --global https.proxy http://<PC_IP>:7897
git config --global http.postBuffer 524288000
```

### 2.2 源码克隆与编译构建

推荐采用浅克隆（`--depth 1`）拉取源码与 Submodules，可大幅缩短克隆耗时并避免连接超时：

```bash
cd ~
git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/FEX-Emu/FEX.git
cd FEX
mkdir Build && cd Build

# 使用 Clang + LLD 链接器构建 Release 版本并开启 LTO 优化
CC=clang CXX=clang++ cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_LINKER=lld \
  -DENABLE_LTO=True \
  -DBUILD_TESTING=False \
  -DENABLE_ASSERTIONS=False \
  -G Ninja ..

# 启动构建（骁龙 860 8 核原生编译约 5~8 分钟）
ninja
```

### 2.3 安装与配置 binfmt_misc

#### 1. 安装二进制文件
```bash
sudo ninja install
```
此步骤会将 FEX 二进制安装到 `/usr/bin/`，并将 systemd 配置文件安装至 `/usr/lib/binfmt.d/FEX-x86.conf` 及 `/usr/lib/binfmt.d/FEX-x86_64.conf`。

#### 2. Arch Linux 下配置 binfmt_misc（避坑）
FEX 构建系统的 `ninja binfmt_misc` 目标中硬编码调用了 `service systemd-binfmt restart`（适用于 Debian/Ubuntu），而 Arch Linux 原生使用 `systemctl`。直接执行会报 `/bin/sh: service: 未找到命令`。

**解决方案**：为 Arch Linux 添加一个轻量级 `service` 兼容包装脚本，或直接使用 systemctl：

```bash
# 创建兼容脚本以顺利通过 ninja binfmt_misc 目标
sudo tee /usr/local/bin/service << 'EOF'
#!/bin/sh
exec systemctl "$2" "$1.service"
EOF
sudo chmod +x /usr/local/bin/service

# 动态注册 binfmt_misc 解释器
sudo ninja binfmt_misc
```

#### 3. 验证与持久化
- 检查内核 binfmt_misc 注册状态：
  ```bash
  cat /proc/sys/fs/binfmt_misc/FEX-x86
  cat /proc/sys/fs/binfmt_misc/FEX-x86_64
  ```
  正常情况下 `interpreter` 应为 `/usr/bin/FEX`，且标志位带有 `flags: POCF`。
- 检查 systemd-binfmt 服务：
  ```bash
  systemctl status systemd-binfmt.service
  ```
  服务为 `active` 状态，重启系统后仍将自动生效。
- 编译完成后恢复休眠策略：
  ```bash
  sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```

### 2.4 下载并配置 x86_64 RootFS

编译安装好 FEX 之后，需要为其挂载一个 x86_64 环境的 Linux 根文件系统。推荐使用 Ubuntu 24.04：

```bash
# 交互式选择安装：
FEXRootFSFetcher

# 或静默非交互式安装（配合代理更佳）：
FEXRootFSFetcher -y -a --distro-name=ubuntu --distro-version=24.04
```

### 2.5 验证 FEX 转译与 binfmt_misc 透明执行

#### 方式一：显式调用 FEX
```bash
FEX /usr/bin/uname -a
```
成功输出类似以下信息，表明 x86_64 转译环境已完全正常：
```text
Linux alarm 6.11.0 # SMP Oct  5 2026 22:56:12 x86_64 x86_64 x86_64 GNU/Linux
```

#### 方式二：binfmt_misc 透明执行（无需 FEX 前缀）
在 binfmt_misc 生效后，系统可在 aarch64 环境下直接运行 x86_64 ELF 格式的可执行文件，内核会自动透明路由给 FEX 执行：
```bash
# 将 RootFS 中的 x86_64 二进制提取到本地测试
FEXBash -c "cp /bin/uname ~/uname_x86_64"

# 在 ARM64 宿主终端直接执行：
~/uname_x86_64 -a
# -> Linux alarm 6.11.0 # SMP Oct  5 2026 22:56:12 x86_64 x86_64 x86_64 GNU/Linux
```

### 2.6 安装 Steam 客户端

从 Valve 官方拉取 deb 包并解压文件：

```bash
cd ~
mkdir steam && cd steam
wget https://repo.steampowered.com/steam/archive/stable/steam-launcher_latest_all.deb

# 解包 deb 安装包
ar x steam-launcher_latest_all.deb
tar -xvf data.tar.xz
```

> ⚠️ **高危警告：切勿直接 `tar -C /` 覆盖**！
> 直接解压到根目录会把系统的 `bin` 和 `lib` 核心系统库覆盖，造成架构不匹配而直接导致系统彻底崩溃！

请严格使用 `-n` 参数（仅拷贝不存在的文件，不覆盖已有核心库）：

```bash
sudo cp -rn etc /
sudo cp -rn lib /
sudo cp -rn usr /
```

### 2.7 启动 Steam

```bash
export STEAMOS=1
export STEAM_RUNTIME=1
FEXBash -c steam
```

> 💡 **提示**：如果在 SSH 远程终端中输入上述命令可能会报错启动失败，这是由于缺少当前图形桌面的 Wayland/X11 环境变量。请在平板本机的 **Konsole** 终端中执行启动命令。

---

## 3. 方案二：Distrobox 容器方案（初次尝试与踩坑留档）

参考资料：[Steam - PostmarketOS Wiki](https://wiki.postmarketos.org/wiki/Steam)

PostmarketOS Wiki 的教程相对较旧，以下记录实际踩坑操作流程：

```bash
# 1. 创建并进入容器
distrobox create --image ubuntu:24.04
distrobox enter ubuntu-24-04

# 2. 修复用户目录权限（容器内默认 user 目录所有者可能异常变为 root）
cd ..
sudo chown -R user:user user
cd user

# 3. 下载 Steam deb 与依赖
wget https://repo.steampowered.com/steam/archive/stable/steam-launcher_latest_all.deb
sudo apt update
sudo apt install pip -y
sudo apt install ./steam-launcher_latest_all.deb -y

# 4. 安装 FEX-Emu 与 RootFS
curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py | python3
FEXRootFSFetcher

# 5. 启动 Steam
FEXBash -c steam
```

### 3.1 踩坑现状与游戏测试结果

1. **文字乱码/豆腐块**：初始启动界面为全英文，中文由于缺少对应字体渲染为方形豆腐块，需要后续安装中文字体及生成对应 locale。
2. **游戏兼容性现状**：尝试运行 Galgame《千恋万花》，游戏启动失败；不同游戏受限于 3D 指令集转换与 Proton/Wine 复杂调用链，兼容情况差异较大，仍有待后续继续深入探索。

---

## 4. 下一步

游戏与转译探索完毕，接下来探索平板上的开发与 AI 辅助能力：[AI Coding Agent 运行环境](./04-ai-agent.md)。
