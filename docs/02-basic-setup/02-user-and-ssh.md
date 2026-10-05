# 用户与基础服务配置

平板设备受限于触控键盘，经常输入长密码或在平板屏幕上长篇敲命令极不方便。本节介绍免密提权、SSH 远程调试与终端会话保持配置。

---

## 1. sudo 免密配置（Danger!）

> 孩子们我不喜欢老是输密码。

如果确信当前环境为个人安全环境，可为普通用户配置免密 `sudo`：

```bash
# 写入免密规则到 sudoers.d
echo 'user ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/user

# 修改文件权限为只读
sudo chmod 0440 /etc/sudoers.d/user
```

> ⚠️ **注意**：免密存在一定的安全风险，请勿在不信任的公共网络或共用设备上开启。
> （把密码肘飞，man！）

---

## 2. 开启并开机自启 SSH 服务

用电脑开热点或通过局域网/USB 远程 SSH 连接进平板，不仅可以使用电脑的实体大键盘，还方便复制粘贴长脚本和命令：

```bash
sudo systemctl enable --now sshd.service
```

---

## 3. 安装 tmux 与会话保持（可选但推荐）

在平板上通过 SSH 敲命令时容易因为网络波动或息屏掉线。安装 `tmux` 后，掉线可直接通过 `tmux a` 无缝恢复现场：

```bash
sudo pacman -S tmux

# 开启鼠标与触控滚轮支持
echo "set-option -g mouse on" >> ~/.tmux.conf
```

---

## 4. 安装离线文档工具（mandoc）

轻量快速的 manual pager，用于在平板本地离线查阅各类命令的手册：

```bash
sudo pacman -S mandoc less
```

---

## 5. 下一步

基础交互搞定后，继续配置中文显示、输入法与虚拟键盘：[中文与输入环境配置](./03-locale-and-input.md)。
