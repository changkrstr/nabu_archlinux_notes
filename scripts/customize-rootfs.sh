#!/bin/bash
set -e

echo "=========================================================="
echo " Starting Nabu Arch Linux ARM RootFS Customization"
echo "=========================================================="

ROOTFS_IMG="${1:-/work/images/rootfs.img}"
MOUNT_DIR="/mnt/rootfs"

if [ ! -f "$ROOTFS_IMG" ]; then
    echo "Error: $ROOTFS_IMG does not exist!"
    exit 1
fi

mkdir -p "$MOUNT_DIR"
echo "[1/7] Mounting rootfs.img..."
mount "$ROOTFS_IMG" "$MOUNT_DIR"

cleanup() {
    echo "[Clean] Unmounting chroot filesystems..."
    umount "$MOUNT_DIR/sys" 2>/dev/null || true
    umount "$MOUNT_DIR/proc" 2>/dev/null || true
    umount "$MOUNT_DIR/dev/pts" 2>/dev/null || true
    umount "$MOUNT_DIR/dev" 2>/dev/null || true
    umount "$MOUNT_DIR/run" 2>/dev/null || true
    umount "$MOUNT_DIR" 2>/dev/null || true
    echo "[Clean] Done unmounting."
}
trap cleanup EXIT ERR

# 挂载虚拟文件系统
mount --bind /dev "$MOUNT_DIR/dev"
mount --bind /dev/pts "$MOUNT_DIR/dev/pts"
mount -t proc /proc "$MOUNT_DIR/proc"
mount -t sysfs /sys "$MOUNT_DIR/sys"

# 配置 DNS 与代理 host 映射
echo "[2/7] Configuring network & DNS..."
mkdir -p "$MOUNT_DIR/run/systemd/resolve"
cat << 'EOF' > "$MOUNT_DIR/run/systemd/resolve/resolv.conf"
nameserver 223.5.5.5
nameserver 119.29.29.29
nameserver 8.8.8.8
EOF

if ! grep -q "host.docker.internal" "$MOUNT_DIR/etc/hosts"; then
    echo "192.168.65.254 host.docker.internal" >> "$MOUNT_DIR/etc/hosts"
fi

# 配置清华镜像源与 archlinuxcn 源
echo "[3/7] Configuring Tsinghua mirrors and archlinuxcn repo..."
cat << 'EOF' > "$MOUNT_DIR/etc/pacman.d/mirrorlist"
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
Server = http://ca.us.mirror.archlinuxarm.org/$arch/$repo
Server = http://nj.us.mirror.archlinuxarm.org/$arch/$repo
EOF

# 移除旧的 archlinuxcn（若有）以防重复
sed -i '/\[archlinuxcn\]/,+2d' "$MOUNT_DIR/etc/pacman.conf" 2>/dev/null || true

# 添加 archlinuxcn 源（首装 keyring 时临时 TrustAll 避免密钥环缺失阻断）
cat << 'EOF' >> "$MOUNT_DIR/etc/pacman.conf"

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF

# 清理残留 gpg agent sockets
rm -f "$MOUNT_DIR/etc/pacman.d/gnupg/S.gpg-agent"* 2>/dev/null || true

echo "[4/7] Entering chroot to install packages..."
chroot "$MOUNT_DIR" /bin/bash << 'EOFCHROOT'
set -e

# 网络代理设置（清华源 direct，外网请求走宿主机 7897 代理端口）
export http_proxy=http://192.168.65.254:7897
export https_proxy=http://192.168.65.254:7897
export no_proxy=mirrors.tuna.tsinghua.edu.cn,tsinghua.edu.cn,127.0.0.1,localhost

echo "--> Updating pacman databases..."
pacman -Sy --noconfirm

echo "--> Installing archlinuxcn-keyring..."
pacman -S --noconfirm --needed archlinuxcn-keyring
pacman-key --populate archlinuxarm archlinuxcn || true

echo "--> Installing Chinese fonts, Fcitx 5 input method, and Firefox..."
pacman -S --noconfirm --needed \
    noto-fonts-cjk \
    wqy-zenhei \
    fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-configtool \
    fcitx5-qt \
    fcitx5-gtk \
    firefox \
    firefox-i18n-zh-cn

echo "--> Configuring Chinese Locales..."
sed -i '/^#zh_CN.UTF-8 UTF-8/s/^#//' /etc/locale.gen
if ! grep -q "^zh_CN.UTF-8 UTF-8" /etc/locale.gen; then
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
fi
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen

echo "LANG=zh_CN.UTF-8" > /etc/locale.conf

echo "--> Configuring input method environment variables (Wayland compliant)..."
# 注意：在 Wayland 下切勿设置 GTK_IM_MODULE=fcitx 或 QT_IM_MODULE=fcitx
cat << 'EOENV' > /etc/environment
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=fcitx
EOENV

cat << 'EOPROF' > /etc/profile.d/fcitx5.sh
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
EOPROF
chmod +x /etc/profile.d/fcitx5.sh

echo "--> Configuring user desktop environment (Plasma + Fcitx5 + Firefox)..."
mkdir -p /home/user/.config/plasma-workspace/env
cat << 'EOPLASMA' > /home/user/.config/plasma-workspace/env/fcitx5.sh
#!/bin/sh
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
EOPLASMA
chmod +x /home/user/.config/plasma-workspace/env/fcitx5.sh

# KDE Plasma 语言与区域
cat << 'EOPLASMALOC' > /home/user/.config/plasma-localerc
[Formats]
LANG=zh_CN.UTF-8

[Translations]
LANGUAGE=zh_CN:en_US
EOPLASMALOC

cat << 'EOPLASMAGLOB' > /home/user/.config/kdeglobals
[Locale]
Country=cn
Language=zh_CN:en_US
EOPLASMAGLOB

# Fcitx 5 开箱即用配置（预置英文键盘 + 拼音输入法）
mkdir -p /home/user/.config/fcitx5
cat << 'EOFCITX' > /home/user/.config/fcitx5/profile
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
EOFCITX

# 自启动 Fcitx 5
mkdir -p /home/user/.config/autostart
cp -f /usr/share/applications/org.fcitx.Fcitx5.desktop /home/user/.config/autostart/ 2>/dev/null || true

# 桌面快捷方式（Firefox）
mkdir -p /home/user/Desktop
cp -f /usr/share/applications/firefox.desktop /home/user/Desktop/ 2>/dev/null || true
chmod +x /home/user/Desktop/firefox.desktop 2>/dev/null || true

# 同步到 /etc/skel 模版目录供未来新建用户继承
mkdir -p /etc/skel/.config/plasma-workspace/env
mkdir -p /etc/skel/.config/fcitx5
mkdir -p /etc/skel/.config/autostart
mkdir -p /etc/skel/Desktop
cp -f /home/user/.config/plasma-workspace/env/fcitx5.sh /etc/skel/.config/plasma-workspace/env/
cp -f /home/user/.config/plasma-localerc /etc/skel/.config/
cp -f /home/user/.config/kdeglobals /etc/skel/.config/
cp -f /home/user/.config/fcitx5/profile /etc/skel/.config/fcitx5/
cp -f /home/user/.config/autostart/org.fcitx.Fcitx5.desktop /etc/skel/.config/autostart/ 2>/dev/null || true
cp -f /home/user/Desktop/firefox.desktop /etc/skel/Desktop/ 2>/dev/null || true

# 修复文件归属为 user:user (1000:1000)
chown -R 1000:1000 /home/user

echo "--> Enabling sshd service on boot..."
systemctl enable sshd.service
ssh-keygen -A || true

echo "--> Cleaning package cache to save disk space..."
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /tmp/*
rm -rf /var/tmp/*

EOFCHROOT

echo "[5/7] Finalizing /etc/pacman.conf (restoring secure SigLevel)..."
sed -i '/\[archlinuxcn\]/{n;/SigLevel = Optional TrustAll/d}' "$MOUNT_DIR/etc/pacman.conf"

echo "[6/7] Resetting hosts..."
sed -i '/host.docker.internal/d' "$MOUNT_DIR/etc/hosts"

echo "[7/7] Unmounting and finishing..."
trap - EXIT ERR
cleanup

echo "=========================================================="
echo " Customization Complete Successfully!"
echo "=========================================================="
