#!/bin/bash
# ==============================================================================
# Script: usb-net-gadget.sh
# Purpose: Initialize USB RNDIS Gadget network on Xiaomi Pad 5 (nabu) Arch Linux
# Install path: /usr/local/bin/usb-net-gadget.sh
# ==============================================================================
set -e

CONFIGFS_ROOT="/sys/kernel/config"
GADGET_DIR="${CONFIGFS_ROOT}/usb_gadget/g1"
UDC_DEVICE="a600000.usb"
IP_ADDR="172.16.42.1/24"

# 1. 挂载 ConfigFS
if ! mountpoint -q "${CONFIGFS_ROOT}"; then
    mount -t configfs none "${CONFIGFS_ROOT}"
fi

# 2. 幂等清理
if [ -d "${GADGET_DIR}" ]; then
    if [ -f "${GADGET_DIR}/UDC" ]; then
        echo "" > "${GADGET_DIR}/UDC" 2>/dev/null || true
    fi
    rm -f "${GADGET_DIR}/configs/c.1/rndis.usb0" 2>/dev/null || true
    rmdir "${GADGET_DIR}/functions/rndis.usb0" 2>/dev/null || true
    rmdir "${GADGET_DIR}/configs/c.1/strings/0x409" 2>/dev/null || true
    rmdir "${GADGET_DIR}/configs/c.1" 2>/dev/null || true
    rmdir "${GADGET_DIR}/strings/0x409" 2>/dev/null || true
    rmdir "${GADGET_DIR}" 2>/dev/null || true
fi

# 3. 创建 gadget 描述
mkdir -p "${GADGET_DIR}"
cd "${GADGET_DIR}"

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Xiaomi"           > strings/0x409/manufacturer
echo "Mi Pad 5"         > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "RNDIS Network Config" > configs/c.1/strings/0x409/configuration

mkdir -p functions/rndis.usb0
ln -s functions/rndis.usb0 configs/c.1/

# 4. 绑定物理 UDC
echo "${UDC_DEVICE}" > UDC

# 5. 自动获取并配置网络接口
sleep 1
USB_IF=$(ls /sys/class/net/ | grep -E '^usb[0-9]+' | sort | tail -n 1)

if [ -n "${USB_IF}" ]; then
    ip addr flush dev "${USB_IF}" || true
    ip addr add "${IP_ADDR}" dev "${USB_IF}"
    ip link set "${USB_IF}" up
    echo "USB Gadget network initialized on interface: ${USB_IF} (${IP_ADDR})"
else
    echo "Error: USB network interface not found!" >&2
    exit 1
fi
