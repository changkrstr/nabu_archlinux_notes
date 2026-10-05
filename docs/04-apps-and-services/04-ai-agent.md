# AI Coding Agent 环境搭建

Arch Linux ARM 的官方仓库软件更新非常及时，可以直接利用系统级 pacman 部署最新的 Node.js 开发运行时与命令行 AI Agent 工具。

---

## 1. 安装 Node.js 与基础工具

```bash
sudo pacman -S nodejs npm git ripgrep fd
```

---

## 2. 将 npm 全局模块目录迁移至用户主目录

为了避免使用 `sudo npm install -g` 污染系统全局目录导致权限冲突，推荐将 npm 全局安装路径迁移到当前用户主目录：

```bash
# 1. 创建用户级全局包目录
mkdir ~/.npm-global

# 2. 配置 npm 前缀
npm config set prefix '~/.npm-global'

# 3. 将新路径写入环境变量 PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 3. 安装与运行终端 Coding Agent

以 `@earendil-works/pi-coding-agent` 为例：

```bash
# 全局安装 agent 命令行工具
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

安装完成后，在任意工作目录执行对应的 agent 命令即可体验在 Linux 平板本地驱动的终端辅助编码。

---

## 4. 下一步

配置好开发与 AI 工具后，继续查看常用桌面软件与系统美化：[日常桌面软件与美化](./05-desktop-apps.md)。
