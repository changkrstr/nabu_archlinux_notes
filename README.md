# 1. 小米平板5 nabu archlinux 配置笔记

- [1. 小米平板5 nabu archlinux 配置笔记](#1-小米平板5-nabu-archlinux-配置笔记)
  - [1.1. 前言](#11-前言)
  - [1.2. 安装](#12-安装)
    - [1.2.1. 分区（多系统）](#121-分区多系统)
    - [1.2.2. 刷入installer包](#122-刷入installer包)
  - [1.3. 配置](#13-配置)
    - [1.3.1. sudo免密（danger!!）](#131-sudo免密danger)
    - [1.3.2. pacman镜像](#132-pacman镜像)
    - [1.3.3. archlinuxcn仓库](#133-archlinuxcn仓库)
    - [1.3.4. 更新软件包.](#134-更新软件包)
    - [1.3.5. 更新内核(并不需要)](#135-更新内核并不需要)
    - [1.3.6. 开机自启sshd](#136-开机自启sshd)
    - [1.3.7. 系统挂起和恢复](#137-系统挂起和恢复)
    - [1.3.8. 电源管理](#138-电源管理)
    - [1.3.9. 装个AI Agent试试](#139-装个ai-agent试试)
    - [1.3.10. mandoc好东西](#1310-mandoc好东西)
    - [1.3.11. AUR助手](#1311-aur助手)
    - [1.3.12. 装个浏览器](#1312-装个浏览器)
    - [1.3.13. 异地组网](#1313-异地组网)
    - [1.3.14. 远程桌面](#1314-远程桌面)
      - [1.3.14.1. 用krdp](#13141-用krdp)
      - [1.3.14.2. 用 sunshine + moonlight.](#13142-用-sunshine--moonlight)
    - [1.3.15. 多设备协同](#1315-多设备协同)
    - [1.3.16. 中文环境](#1316-中文环境)
      - [1.3.16.1. 中文字体和locale](#13161-中文字体和locale)
      - [1.3.16.2. 中文输入法:](#13162-中文输入法)
      - [1.3.16.3. 系统设置](#13163-系统设置)
      - [1.3.16.4. 关于虚拟键盘](#13164-关于虚拟键盘)
    - [1.3.17. 美化](#1317-美化)
    - [1.3.18. 安装docker](#1318-安装docker)
    - [1.3.19. 科学上网工具](#1319-科学上网工具)
    - [1.3.20. 安装steam](#1320-安装steam)
      - [1.3.20.1. 自行编译FEX-Emu（推荐）](#13201-自行编译fex-emu推荐)
      - [1.3.20.2. 初次尝试（old）](#13202-初次尝试old)
  - [1.4. 维护](#14-维护)
  - [1.5. 进阶](#15-进阶)

## 1.1. 前言

必要准备：

- 使用的rootfs镜像与UEFI: [Github 仓库: Nabu Arch](https://github.com/Kumar-Jy/Nabu-arch-images)
- 推荐的TWRP: V4-TWRP-NABU-10-05.img [TWRP下载地址](https://github.com/Kumar-Jy/twrp_device_xiaomi_nabu/releases/tag/mod-hybrid)
- 需要一台有adb和fastboot的电脑

> 这两个仓库几乎是傻瓜式的，安装非常简单。
> TWRP 有个文件名带HYBRID的, 如果启动不了下那个试试.
> TWRP启动不了也有可能是boot的原因, 试试先刷一个boot.

## 1.2. 安装

> 这会格式化你的userdata，注意备份你的安卓数据

### 1.2.1. 分区（多系统）

设备重启到bootloader连接电脑

启动到刚才下载的twrp，哪怕twrp一直卡在启动页面也行：

```bash
fastboot boot path/to/twrp.img
```

进行分区:

```bash
adb shell
```

```bash
# in adb shell
partition
```

这个分区脚本是交互式的，比较简单。如果你用的是其他的twrp可能会不一样，可以参考别的资料。

### 1.2.2. 刷入installer包

push到sdcard刷入或者直接sideload

如果那两个twrp都卡在twrp启动页面，push过去没法刷入，也没法sideload怎么办呢？

实测可以刷个任意第三方rom的boot，启动到他的recovery再侧载，比如crDroid。

```bash
adb sideload path/to/arch-nabu-installer-plasma.zip
```

重启，进入多系统选择界面，音量上下切换，电源键确认. 进入arch.

## 1.3. 配置

### 1.3.1. sudo免密（danger!!）

孩子们,我不喜欢sudo老要我输密码：

```bash
sudo echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user
sudo chmod 0440 /etc/sudoers.d/user
```

把密码肘飞，man！

### 1.3.2. pacman镜像

编辑 `/etc/pacman.d/mirrorlist`，在文件的最顶端添加以下配置；您可以同时注释掉其它所有镜像。

```
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
```

更新软件包缓存：

```
sudo pacman -Syy
```

### 1.3.3. archlinuxcn仓库

官方仓库地址：https://repo.archlinuxcn.org

使用方法：在 /etc/pacman.conf 文件末尾添加以下两行：

```
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
```

之后通过以下命令安装 archlinuxcn-keyring 包导入 GPG key。

```
sudo pacman -Sy archlinuxcn-keyring
```

### 1.3.4. 更新软件包.

```bash
sudo pacman -Syu
```

### 1.3.5. 更新内核(并不需要)

> 第一次启动发现没有电量和充电显示，病急乱投医尝试了更新内核，其实不知道是不是真的有用。
> 后面又遇到几次开机没电量，重启就好了。

```bash
sudo pacman -Syu linux-nabu linux-nabu-headers
```

重启。

### 1.3.6. 开机自启sshd

自用，电脑开个热点然后ssh连进来复制粘贴方便点。

```bash
sudo systemctl enable --now sshd.service
```

（可选） 安装tmux，以后ssh进去先开一个tmux，掉线了直接`tmux a`恢复。

```bash
sudo pacman -S tmux
echo "set-option -g mouse on" >> ~/.tmux.conf
```

### 1.3.7. 系统挂起和恢复

仓库README写了这玩意正常，但是我实际使用过程中还是遇到几次黑屏然后再也点不亮。

踩过的一些坑：安装tlp或者power-profile-daemon, 别看任务栏上电源菜单说可能支持电源管理方案，实际就是不支持，装这两能用，前者有几个profile但是不知道是不是真的有效，后者装完直接显示不支持。两者都会破坏挂起恢复，不知道怎么修。

即使没装电源方案，依然有可能黑屏后点不亮，不知道怎么修, 但是如果你有外接键盘, 有时候是可以点亮的.

后来我找到了一个好办法：

设置 -> 电源管理 -> AC/电池/低电量 ->

三个选项卡的`电源按下时:`和`笔记本合盖时:`全部改成锁屏,而不是睡眠.

空闲时改成什么也不做.

在把关闭屏幕设置成`锁屏时:立即关闭`.

恭喜你找到了和使用安卓时一样的手感.

至于续航，祝你好运。

可能是这个作者做的内核的问题，不论如何配置黑屏后就是有可能怎么也点不亮，我也不会修，自求多福吧。

### 1.3.8. 电源管理

上一节刚说tlp会破坏系统挂起和恢复，现在就要打脸了。

还是推荐装个tlp集中管理电源设置。

至于挂起和恢复，只能祝我们好运了。(可以把tlp的 启用默认设置 关闭)

```bash
sudo pacman -S networkmanager tlp tlp-pd tlp-rdw tlpui
sudo systemctl enable --now tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
```

### 1.3.9. 装个AI Agent试试

arch的软件包很新, 直接用pacman装nodejs.

```bash
sudo pacman -S nodejs npm git

# 把npm全局包的目录迁到用户目录
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 装个PI看看效果
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

### 1.3.10. mandoc好东西

```bash
sudo pacman -S mandoc less
```

### 1.3.11. AUR助手

比如使用paru. 我是新玩家不知道这些都有啥区别随便装个.

```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### 1.3.12. 装个浏览器

火狐

```bash
sudo pacman -S firefox
```

### 1.3.13. 异地组网

以tailscale为例

```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

打开浏览器登录, 用其他设备的浏览器也可以.

### 1.3.14. 远程桌面

#### 1.3.14.1. 用krdp

```bash
sudo pacman -S krdp
```

然后去设置里调. windows系统使用自带远程桌面软件连接时, 勾选保存凭据才能弹出输入密码, 否则登录失败.

windows做主控端需要加入智能缩放配置:

保存一个rdp配置文件, 在末尾加上`smart sizing:i:1`.

#### 1.3.14.2. 用 sunshine + moonlight.

sunshine官方有pacman仓库, 但是那里面没给aarch64的包.

可以到github仓库下载appimage或者flatpak包.

直接

```bash
chmod +x path/to/sunshine.appimage
path/to/sunshine.appimage
```

或者

```bash
# flatpak安装
# Add Flathub repository:
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Install dev.lizardbyte.app.Sunshine application or runtime:
flatpak install flathub dev.lizardbyte.app.Sunshine
# Run dev.lizardbyte.app.Sunshine application:
flatpak run dev.lizardbyte.app.Sunshine
```

安装moonlight

```bash
sudo pacman -S moonlight-qt
```

### 1.3.15. 多设备协同

```bash
sudo pacman -S kdeconnect
```

kde connect是可以走tailscale连接的，需要手动修改配置（为毛移动端app可以直接添加）

找到配置文件 `~/.config/kdeconnect/config` (Linux) or `%LOCALAPPDATA%\kdeconnect\config` (Windows)，

添加一行`customDevices`，比如

```text
customDevices=192.0.2.42,192.0.2.43
```

### 1.3.16. 中文环境

#### 1.3.16.1. 中文字体和locale

```bash
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji
```

删掉`/etc/locale.gen`中 `zh_CN.UTF-8 UTF-8` 前面的`#`.

直接写一条应该也行

```bash
# 直接写gen配置
echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
# locale-gen
sudo locale-gen
# locale配置
echo 'LANG=zh_CN.UTF-8' | sudo tee /etc/locale.conf
```

#### 1.3.16.2. 中文输入法:

```bash
sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-qt fcitx5-gtk fcitx5-configtool

mkdir -p ~/.config/plasma-workspace/env/
nano ~/.config/plasma-workspace/env/fcitx5.sh
```

脚本里面写

```bash
#!/bin/sh
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
```

```bash
chmod +x ~/.config/plasma-workspace/env/fcitx5.sh
```

#### 1.3.16.3. 系统设置

-> local and language -> language -> add 简体中文 -> 重启。

重启后，进行以下设置：

打开 系统设置 -> 输入设备 -> 虚拟键盘，选择 Fcitx 5，然后点击“应用”。

打开 系统设置 -> 区域设置 -> 输入法，点击“运行 Fcitx”，然后点击“添加输入法”，在“简体中文”下找到并添加 Pinyin 即可。

之后，你就可以通过 Ctrl + 空格 来切换中英文输入了。

#### 1.3.16.4. 关于虚拟键盘

仓库作者构建的rootfs自带一个OSKB着实难用，不能输入中文，优点是有键盘上的功能键。

Plasma键盘可以输入中文，相对比较好用但是，没有功能键。

fcitx5键盘仅仅是作为外接键盘输入法后端使用的，不具备虚拟键盘功能。

这几个键盘同时只能用一个，切换不方便，且虚拟键盘和外接键盘同时只能有一个输入中文。

暂时没找到什么好的解决方案.

### 1.3.17. 美化

玩机不得不品的一环

我不会。

### 1.3.18. 安装docker

```bash
sudo pacman -S docker

sudo systemctl enable --now docker.service

sudo usermod -aG docker $USER
```

孩子们为什么我的docker启动不了? systemctl start也不行.

孩子们别怕有ai大人，以下是ai提供的修复过程。

Arch Linux 默认安装的 iptables 使用的是 iptables-nft（基于 nftables 兼容层）。

Docker 在初始化默认网桥网络时，调用了带 -m addrtype 扩展的 iptables 规则。在 nft 模式下，这需要内核提供 nft_compat 模块。

当前系统的内核（6.14.11-10-nabu）未编译 CONFIG_NFT_COMPAT，但完整支持传统的 iptables-legacy 及相关模块，导致 iptables-nft 报错：

```text
Warning: Extension addrtype revision 0 not supported, missing kernel module?
iptables v1.8.13 (nf_tables): RULE_APPEND failed (No such file or directory): rule in chain PREROUTING
```

安装 iptables-legacy 替换 iptables：

```bash
sudo pacman -S iptables-legacy
```

清除启动失败计数并启动 Docker 服务：

```bash
sudo systemctl reset-failed docker
sudo systemctl start docker
sudo systemctl enable docker
```

关于docker镜像 各位自求多福吧。

### 1.3.19. 科学上网工具

AUR里啥都有。

### 1.3.20. 安装steam

steam没有公开的arm64构建的版本(据说有个snap包), 装起来挺不方便.

> 有没有人试过AUR仓库的 fex-emu-wine-git ? 不用试了，不是我们要的那个东西。

我也是第一次装, 找到一篇参考资料试试.

[Steam - PostmarketOS Wiki](https://wiki.postmarketos.org/wiki/Steam)

照这篇文章，需要先开一个ubuntu容器，里面装fex emu, 然后装steam.

我有一些其他想法，直接装fex emu呢？ 试过archlinuxcn仓库的fex-emu，一直报段错误，不会修。

#### 1.3.20.1. 自行编译FEX-Emu（推荐）

昨晚尝试编译FEX-Emu，结果非常Amazing啊，完美运行。

[FEX-Emu Wiki Setting Up FEX](https://wiki.fex-emu.com/index.php/Development:Setting_up_FEX)

如果不会操作或者嫌麻烦，直接叫AI给你搞定。

```text
帮我编译FEX-emu，参考https://wiki.fex-emu.com/index.php/Development:Setting_up_FEX。
```

然后给FEX装一个Rootfs，推荐ubuntu24.04，好像是这里面几个包体最小的。

```bash
FEXRootFSFetcher
```

可能报错说没有squashfuse，pacman装一下。

完事。

```
[user@alarm ~]$ FEX /usr/bin/uname -a
Linux alarm 6.11.0 #FEX-2609-137-g0df84d3 SMP Sep 30 2026 00:58:18 x86_64 x86_64 x86_64 GNU/Linux
```

这样FEX就是装好了。

启动steam.

```bash
cd ~
mkdir steam && cd steam
wget https://repo.steampowered.com/steam/archive/stable/steam-launcher_latest_all.deb

ar x steam-launcher_latest_all.deb

# 这一步千万要小心，不要想着图省事直接tar -C ，会把bin和lib里的文件覆盖，导致架构不同系统崩溃
tar -xvf data.tar.xz
# 同样要小心别把一些东西覆盖了
sudo cp -rn etc /
sudo cp -rn lib /
sudo cp -rn usr /

export STEAMOS=1
export STEAM_RUNTIME=1
FEXBash -c steam
```

如果在ssh连接中输上面最后一行命令，可能会启动失败，我猜是因为有些桌面相关的环境变量没有传给ssh，尝试用Konsole来执行。

#### 1.3.20.2. 初次尝试（old）

第一次尝试的记录，steam启动成功，游戏无法运行。

postmarketOS那篇教程有些过时了，踩了不少坑。

下面是我的步骤。

```bash
distrobox create --image ubuntu:24.04
distrobox enter ubuntu-24-04
```

进入容器之后

```bash
# 修复用户目录权限，不知道为什么user目录的所有者会是root太奇怪了
cd ..
sudo chown -R user:user user
cd user
# 下载steam deb包
wget https://repo.steampowered.com/steam/archive/stable/steam-launcher_latest_all.deb

sudo apt update

sudo apt install pip -y

sudo apt install ./steam-launcher_latest_all.deb -y

curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py | python3

# 如果FEX提示找不到RootFS，再运行下面的命令
FEXRootFSFetcher
```

Steam启动!

```bash
FEXBash -c steam
```

这时候界面应该是全英文的，而且中文是豆腐块，可能是需要安装中文字体和生成locale.

孩子们我已经试过了，千恋万花启动失败。（失望）

改天试试别的方案。

先分享一下尝试过的方案：

1. 使用来自archlinuxcn仓库的fex-emu，使用`FEXRootFSFetcher`下载Arch，Ubuntu的RootFS均无法启动，`FEX /usr/bin/uname` 直接报 段错误。与此对比（上面的方案），`FEX /usr/bin/uname -a`应该正常返回x86_64等信息。
2. 使用原wiki提到的`distrobox create --image ubuntu:24.04 --root --init`，加了这两个参数，安装FEX-emu后，报错无法连接FEXServer.Socket.

## 1.4. 维护

如何备份、恢复我们的arch？改日再研究。

## 1.5. 进阶

自己构建 内核 RootFS ?

我用最直白，最xx的方式告诉你，我不会。

后面区域以后再来探索吧。
