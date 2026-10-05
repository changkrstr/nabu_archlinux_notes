# 电源管理与休眠配置

在移动 SoC（高通骁龙 860）上运行主线/第三方 Linux 内核时，电源管理与屏幕休眠/唤醒往往是坑最多的环节。

---

## 1. 系统挂起与恢复踩坑分析

虽然部分发行版/镜像的说明写着支持挂起（Suspend），但在实际使用中，往往会遇到**息屏或挂起后黑屏再也点不亮**的情况。

- **电源方案冲突**：安装 `tlp` 或 `power-profile-daemon` 后，任务栏电源菜单虽然可能显示支持方案，但实际适配并不完善，且容易破坏挂起恢复流程。
- **唤醒排查**：在黑屏无法通过屏幕触控点亮时，如果有外接物理键盘，敲击键盘有时可以唤醒屏幕；但仅靠触控屏经常无法点亮。

**十月一日更新**：经过我今日瞎几把按发现，**交替点按电源和音量下**可以稳定点亮屏幕。

---

## 2. 避免黑屏死锁的最佳实践（强烈推荐）

经过实测，最稳妥且手感接近 Android 平板的电源配置策略是：**用“锁屏+关屏”替代“深度睡眠”**。

在 KDE Plasma 中进行如下设置：

1. 打开 **系统设置** -> **电源管理**（Power Management）。
2. 在 **交流电源**（AC）、**电池**（On Battery）、**低电量**（On Low Battery）三个选项卡中均进行如下调整：
   - 将 **“按下电源按键时”** 改为：`锁屏`（Lock screen，切勿选睡眠）。
   - 将 **“合上笔记本盖时”** 改为：`锁屏`（Lock screen）。
   - 将 **“空闲时”** 改为：`什么也不做`（Do nothing）。
3. 在屏幕关闭策略中：
   - 将屏幕关闭设置勾选为 **“锁屏时立即关闭屏幕”**。

> 💡 如此配置后，轻按电源键即可立即锁屏息屏，再次轻按即可点亮解锁，体验与常规平板设备完全一致，有效规避了内核 Suspend 唤醒失败导致的硬死机。

---

## 3. 安装与配置 TLP 电源管理套件

如果需要集中微调电池充放电、CPU 调速或外设省电策略，可安装并启用 TLP 套件：

```bash
# 安装 TLP 核心套件与图形配置界面
sudo pacman -S networkmanager tlp tlp-pd tlp-rdw tlpui

# 启用 TLP 服务
sudo systemctl enable --now tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable NetworkManager-dispatcher.service

# 屏蔽 systemd 自带的 rfkill 冲突服务
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
```

> 📌 **避坑建议**：
> 在 TLP 界面（`tlpui`）中，建议关闭部分激进的默认自动挂起选项，避免因外设或总线休眠再次破坏唤醒稳定性。

---

## 4. 下一步

基础系统与电源调控完成，下一步进入有线与网络互联配置：[USB 调试与 RNDIS 有线网络](../03-network/01-usb-gadget-network.md)。
