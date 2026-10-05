#!/bin/bash
set -e

ROOTFS_IMG="${1:-/work/images/rootfs.img}"
MOUNT_DIR="/mnt/rootfs"

mkdir -p "$MOUNT_DIR"
mount "$ROOTFS_IMG" "$MOUNT_DIR"

cleanup() {
    umount "$MOUNT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== [验证 1: 清华镜像源配置] ==="
cat "$MOUNT_DIR/etc/pacman.d/mirrorlist"
echo ""

echo "=== [验证 2: archlinuxcn 软件源配置] ==="
tail -n 8 "$MOUNT_DIR/etc/pacman.conf"
echo ""

echo "=== [验证 3: 中文 Locale 与字体配置] ==="
echo "/etc/locale.conf: $(cat "$MOUNT_DIR/etc/locale.conf")"
echo "locale.gen enabled:"
grep -v '^#' "$MOUNT_DIR/etc/locale.gen" | grep -v '^$'
echo "中文字体包验证:"
ls -d "$MOUNT_DIR/usr/share/fonts/noto-cjk"* 2>/dev/null || true
ls -d "$MOUNT_DIR/usr/share/fonts/wenquanyi"* 2>/dev/null || true
echo ""

echo "=== [验证 4: Fcitx5 输入法与环境变量] ==="
echo "/etc/environment:"
cat "$MOUNT_DIR/etc/environment"
echo "profile.d/fcitx5.sh:"
cat "$MOUNT_DIR/etc/profile.d/fcitx5.sh"
echo "plasma fcitx5.sh:"
cat "$MOUNT_DIR/home/user/.config/plasma-workspace/env/fcitx5.sh"
echo "user profile:"
cat "$MOUNT_DIR/home/user/.config/fcitx5/profile"
echo "user localerc:"
cat "$MOUNT_DIR/home/user/.config/plasma-localerc"
echo "autostart desktop:"
ls -la "$MOUNT_DIR/home/user/.config/autostart"
echo ""

echo "=== [验证 5: Firefox 浏览器] ==="
test -f "$MOUNT_DIR/usr/bin/firefox" && echo "Firefox binary: OK"
test -f "$MOUNT_DIR/usr/lib/firefox/browser/extensions/langpack-zh-CN@firefox.mozilla.org.xpi" && echo "Firefox zh-CN langpack: OK"
test -f "$MOUNT_DIR/home/user/Desktop/firefox.desktop" && echo "Desktop shortcut: OK"
echo ""

echo "=== [验证 6: 系统 resolve 与文件权限与 sshd] ==="
ls -la "$MOUNT_DIR/etc/resolv.conf"
ls -la "$MOUNT_DIR/home/user" | head -n 10
echo "sshd.service enabled:"
ls -la "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/sshd.service"
echo ""

echo "=== [验证 7: 磁盘空间使用情况] ==="
df -h "$MOUNT_DIR"
