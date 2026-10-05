# 日常桌面软件与美化

本节记录小米平板 5 在日常使用中涉及的图形浏览器、科学上网代理工具与 KDE 桌面美化相关内容。

---

## 1. 网页浏览器：Firefox

Arch Linux ARM 官方仓库提供针对 `aarch64` 原生构建的 Firefox：

```bash
sudo pacman -S firefox
```

> 💡 **触控体验提示**：
> 在 Wayland 模式下，Firefox 对高分触控屏的双指缩放、平滑滑动与手势支持非常良好，体验远好于 XWayland 兼容层下的浏览器。

---

## 2. 科学上网与代理工具

对于日常开发依赖的海外镜像与 GitHub 仓库，可以通过 AUR 助手安装成熟的代理客户端：

- **内核与服务**：如 `mihomo` / `clash-meta` / `sing-box` 等均在 AUR 或 archlinuxcn 仓库中提供 aarch64 架构预编译包。
- **图形与 Web 控制台**：如 `v2raya`、`clash-verge-rev` 等可结合个人使用习惯选择安装。

```bash
# 示例：通过 paru 快速检索与安装
paru -S mihomo
```

---

## 3. KDE 桌面美化心得

美化是玩机与定制 Linux 桌面不可或缺的一环：

- **主题与图标**：可在 **系统设置** -> **外观** (Global Theme / Icons) 中直接在线浏览下载适合触控平板的圆角高对比度图标（如 Tela / Papirus）。
- **任务栏与 Dock 模式**：可以将默认底部任务栏调整为悬浮居中 Dock，更符合触控设备的人机工程学。
- **字体渲染**：搭配前面安装的 Noto 字体，可在字体设置中开启次像素平滑（Sub-pixel rendering）与轻微微调（Slight hinting）。

---

## 4. 下一步

桌面应用部署完毕后，进入系统的维护与备份进阶篇：[系统维护与备份思考](../05-advanced/01-maintenance.md)。
