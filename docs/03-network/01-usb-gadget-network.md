# USB 调试与 RNDIS 有线网络

通过 USB Type-C 数据线将小米平板 5（nabu）与电脑直接连接，利用 Linux 内核的 USB Gadget（ConfigFS）与 RNDIS 协议，将平板模拟为虚拟网卡，实现极速稳定的点对点有线网络与 SSH 调试。

暂时只捣鼓出了，平板和电脑通过usb连接组一个子网，但是互联网的访问似乎不能共享，以后再研究。

---

## 1. UDC 核心概念

**UDC** = USB Device Controller（USB 设备控制器）。

- 它是平板 SoC 内部处理 USB 设备模式（Peripheral/Gadget 模式）的硬件控制器芯片，在小米平板 5 上的驱动名称为 `a600000.usb`。
- 内核 ConfigFS 中的 `UDC` 虚拟文件即控制器的“软开关”：
  - 写入控制器名称（如 `echo "a600000.usb" | sudo tee UDC`）= 绑定并激活 USB Gadget；
  - 写入空字符串（如 `echo "" | sudo tee UDC`）= 解绑并断开连接。
- 绑定生效后，平板端才会生成对应的网络接口（例如 `usb0` 或 `usb1`），Windows 电脑端才能识别到 RNDIS 虚拟网卡设备；解绑后设备即刻断开（等同于物理拔线）。

检查系统 UDC 名称：

```bash
ls /sys/class/udc/
# 输出应包含 a600000.usb
```

---

## 2. 手动配置全流程

### 2.1 平板端（Arch Linux）

```bash
# 1. 挂载 ConfigFS（如系统已自动挂载则可跳过）
sudo mount -t configfs none /sys/kernel/config

# 2. 进入 gadget 配置目录并创建 gadget 实例 g1
cd /sys/kernel/config/usb_gadget
sudo mkdir g1 && cd g1

# 3. 写入 USB 设备标识信息
echo 0x1d6b | sudo tee idVendor  # Linux Foundation
echo 0x0104 | sudo tee idProduct # Multifunction Composite Gadget
echo 0x0100 | sudo tee bcdDevice
echo 0x0200 | sudo tee bcdUSB

# 4. 创建英文描述字符串与配置
sudo mkdir -p strings/0x409
echo "fedcba9876543210" | sudo tee strings/0x409/serialnumber
echo "Xiaomi"           | sudo tee strings/0x409/manufacturer
echo "Mi Pad 5"         | sudo tee strings/0x409/product

sudo mkdir -p configs/c.1/strings/0x409
echo "RNDIS Network Config" | sudo tee configs/c.1/strings/0x409/configuration

# 5. 创建 RNDIS 功能实例并链接到配置
sudo mkdir -p functions/rndis.usb0
sudo ln -s functions/rndis.usb0 configs/c.1/

# 6. 绑定到物理 UDC 控制器
echo "a600000.usb" | sudo tee UDC

# 7. 查看分配到的网卡名称（通常为 usb0 或 usb1）
ip link show

# 8. 为平板端网卡配置固定静态 IP 并启用（假设接口名为 usb1）
sudo ip addr flush dev usb1
sudo ip addr add 172.16.42.1/24 dev usb1
sudo ip link set usb1 up

# 9. 确保 SSH 服务运行
sudo systemctl start sshd
```

### 2.2 电脑端（Windows）配置

1. 打开 **设备管理器**：
   - 若出现带黄色叹号的 `RNDIS` 设备（设备状态显示代码 28，驱动未找到）：
   - 右键该设备 -> **更新驱动程序** -> **浏览我的电脑以查找驱动程序** -> **让我从计算机上的可用驱动程序列表中选取**。
   - 在设备类别中选择 **网络适配器** -> 厂商选择 **Microsoft** -> 型号选择 **基于远程 NDIS 的 Internet 共享设备**（Remote NDIS Compatible Device）。
2. 配置 Windows 虚拟网卡 IP：
   - 打开 **网络连接**（`ncpa.cpl`），找到刚刚识别出的 RNDIS 适配器。
   - 属性 -> **Internet 协议版本 4 (TCP/IPv4)** -> 手动填写：
     - **IP 地址**：`172.16.42.2`
     - **子网掩码**：`255.255.255.0`
     - **默认网关**：留空
3. 连通性测试与 SSH 连接：
   ```cmd
   ping 172.16.42.1
   ssh user@172.16.42.1
   ```

---

## 3. 连接控制与清理

### 3.1 仅断开网络（保留 USB Gadget 设备）

```bash
sudo ip link set usb1 down
```

_恢复网络_：`sudo ip link set usb1 up`

### 3.2 彻底断开（模拟拔出 USB 线）

```bash
cd /sys/kernel/config/usb_gadget/g1
echo "" | sudo tee UDC
```

- 平板端网络接口消失，Windows 端的 RNDIS 设备同步断开。
- 配置仍然保存在内核内存中，若需重新连线，仅需再次写入：`echo "a600000.usb" | sudo tee UDC`。

### 3.3 完全注销并删除 Gadget 节点

```bash
cd /sys/kernel/config/usb_gadget/g1
echo "" | sudo tee UDC               # 1. 必须先解绑 UDC
sudo rm configs/c.1/rndis.usb0       # 2. 删除软链接
sudo rmdir functions/rndis.usb0      # 3. 删除功能目录（必须用 rmdir）
sudo rmdir configs/c.1/strings/0x409 # 4. 逐层向上 rmdir
sudo rmdir configs/c.1
sudo rmdir strings/0x409
cd .. && sudo rmdir g1
```

> ⚠️ **重要规则**：ConfigFS 是内核暴露的虚拟文件系统接口，**绝对不能直接使用 `rm -rf` 删除其中的属性文件**，否则会报错“不允许的操作”；只能通过 `rmdir` 移除目录或通过 `rm` 删除软链接。

---

## 4. 常见问题排查速查表

| 问题表现                                          | 核心原因                              | 解决方案                                                        |
| :------------------------------------------------ | :------------------------------------ | :-------------------------------------------------------------- |
| `modprobe g_ether` 提示找不到模块                 | 主线/第三方内核未编译单体 gadget 驱动 | 改用当前标准的 ConfigFS + RNDIS 方案                            |
| `rm` 删除 ConfigFS 文件报 Operation not permitted | 内核属性文件不支持直接删除            | 只能使用 `rmdir` 删除功能目录，用 `rm` 删除符号链接             |
| Windows 设备管理器识别为 CDC ECM 但无驱动         | Windows 默认未自带 ECM 驱动           | 平板端改用兼容性更好的 RNDIS 功能协议                           |
| RNDIS 设备状态为 Code 28                          | 缺少自动硬件 ID 匹配                  | 手动更新驱动选择 Microsoft -> 基于远程 NDIS 的网络设备          |
| 找不到 `usb0` 接口                                | 接口名由内核根据已有网络设备动态分配  | 使用 `ip link show` 或检测 `/sys/class/net/usb*` 动态匹配实际名 |
| 断开后重新插入无法联网                            | UDC 状态被解绑重置                    | 重新向 `UDC` 写入控制器名称并重配 IP                            |

---

## 5. 开机自动持久化（Systemd 服务化）

ConfigFS 属于易失性虚拟文件系统，重启后即失效。为了实现“开机插入数据线即可免密直连”，可将其制作成 Systemd 自动化服务。

### 5.1 自动化配置脚本 `/usr/local/bin/usb-net-gadget.sh`

```bash
#!/bin/bash
set -e

CONFIGFS_ROOT="/sys/kernel/config"
GADGET_DIR="${CONFIGFS_ROOT}/usb_gadget/g1"
UDC_DEVICE="a600000.usb"
IP_ADDR="172.16.42.1/24"

# 1. 确保 ConfigFS 挂载
if ! mountpoint -q "${CONFIGFS_ROOT}"; then
    mount -t configfs none "${CONFIGFS_ROOT}"
fi

# 2. 如果已存在，先做幂等重置
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

# 3. 创建 gadget
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

# 4. 绑定 UDC
echo "${UDC_DEVICE}" > UDC

# 5. 动态检测新创建的 USB 网络接口名并分配 IP
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
```

赋予执行权限：

```bash
sudo chmod +x /usr/local/bin/usb-net-gadget.sh
```

### 5.2 Systemd 服务单元文件 `/etc/systemd/system/usb-net.service`

```ini
[Unit]
Description=USB Gadget Network (RNDIS) for Mi Pad 5
After=systemd-modules-load.service sysinit.target
Wants=systemd-modules-load.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/usb-net-gadget.sh
ExecStop=/bin/bash -c 'echo "" > /sys/kernel/config/usb_gadget/g1/UDC 2>/dev/null || true; for iface in $(ls /sys/class/net/ | grep -E "^usb[0-9]+"); do ip link set $$iface down 2>/dev/null || true; done'

[Install]
WantedBy=multi-user.target
```

### 5.3 启用与操作

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now usb-net.service

# 查看当前运行状态
sudo systemctl status usb-net.service

# 临时断开 USB 有线网络（解绑 UDC）
sudo systemctl stop usb-net.service

# 重新连接
sudo systemctl start usb-net.service
```

---

## 6. 下一步

配置好局域网与有线直连后，可进一步配置广域网互通：[Tailscale 异地组网](./02-tailscale.md)。
