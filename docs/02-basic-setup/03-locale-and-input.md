# 中文与输入环境配置

Arch Linux ARM 默认镜像为全英文环境，且触控平板高度依赖虚拟键盘与中文输入法支持。

---

## 1. 中文字体与 Locale 配置

### 1.1 安装 Noto 常用字体

```bash
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji
```

### 1.2 生成并设置中文 Locale

编辑 `/etc/locale.gen`，取消 `zh_CN.UTF-8 UTF-8` 前面的 `#` 注释；或直接通过命令追加：

```bash
# 追加中文 UTF-8 支持
echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen

# 生成 locale
sudo locale-gen

# 设置全局默认语言
echo 'LANG=zh_CN.UTF-8' | sudo tee /etc/locale.conf
```

---

## 2. 安装与配置 Fcitx 5 中文输入法

### 2.1 安装软件包

```bash
sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-qt fcitx5-gtk fcitx5-configtool
```

### 2.2 配置 Plasma 会话环境变量

创建环境自启脚本：

```bash
mkdir -p ~/.config/plasma-workspace/env/
nano ~/.config/plasma-workspace/env/fcitx5.sh
```

在文件中写入以下环境变量：

```bash
#!/bin/sh
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
```

赋予可执行权限：

```bash
chmod +x ~/.config/plasma-workspace/env/fcitx5.sh
```

---

## 3. KDE 系统设置与启用

1. **设置系统语言**：
   - 打开 **系统设置** -> **Regional Settings (区域设置)** -> **Language (语言)**。
   - 点击 **Add...** 添加 **简体中文**，应用后重启平板。
2. **启用虚拟键盘**：
   - 重启后打开 **系统设置** -> **输入设备** -> **虚拟键盘**。
   - 选择 **Fcitx 5**，点击“应用”。
3. **添加拼音输入法**：
   - 打开 **系统设置** -> **区域设置** -> **输入法**。
   - 点击“运行 Fcitx”，随后点击“添加输入法”，在“简体中文”列表中找到并添加 **Pinyin (拼音)** 即可。
4. **日常切换**：
   - 快捷键使用 `Ctrl + Space` 即可自由切换中英文输入。

---

## 4. 触控平板虚拟键盘的现状与对比

| 虚拟键盘方案 | 优点 | 缺点 | 适用场景 |
| :--- | :--- | :--- | :--- |
| **镜像自带 OSKB** | 带有方向键、Esc、Ctrl、Alt 等完备功能键 | **无法输入中文**，UI 偏简陋 | 纯命令行排错、没有外接键盘时的紧急维护 |
| **Plasma 虚拟键盘** | 原生集成、UI 现代顺滑、支持中文输入 | 缺失快捷键/功能键区 | 日常纯触控平板娱乐、网页浏览 |
| **Fcitx 5 虚拟键盘** | 无缝配合拼音输入体系 | 仅作为输入法后端，本身不具备完整软键盘弹出能力 | 主要作为外接实体键盘/磁吸键盘的中文输入后端 |

> 📌 **痛点提示**：
> 目前在 Wayland/Plasma 下，这几个软键盘同时只能启用一个，无法快速一键无感切换；且虚拟键盘和外接实体键盘同时只能有一方很好地输入中文。如果重度输入，仍强烈建议配合蓝牙/Type-C 实体键盘使用。

---

## 5. 下一步

输入法与中文搞定后，继续配置至关重要的电源管理与防休眠黑屏方案：[电源管理与休眠配置](./04-power-management.md)。
