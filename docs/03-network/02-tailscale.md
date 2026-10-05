# Tailscale 异地虚拟局域网

为了在离开本地 Wi-Fi 或没有数据线直连时依然能远程访问小米平板 5，可以使用 Tailscale 进行 P2P 穿透与跨网络互联。

---

## 1. 安装与服务启用

在 Arch Linux ARM 下直接通过 pacman 安装 Tailscale 官方包：

```bash
# 1. 安装 tailscale 软件包
sudo pacman -S tailscale

# 2. 启用并立即启动后台守护进程
sudo systemctl enable --now tailscaled
```

---

## 2. 节点认证与加入网络

在终端执行登录命令：

```bash
sudo tailscale up
```

终端会输出一段类似于 `https://login.tailscale.com/a/xxxxxx` 的认证 URL：
- 可以直接在平板内置浏览器中打开该链接完成登录；
- 或者复制该链接到电脑/手机浏览器中完成身份认证。

认证成功后，平板将获得一个固定的 Tailscale 内网 IP（形如 `100.x.y.z`）。

---

## 3. 常用操作与验证

```bash
# 查看本机 Tailscale IP 与当前状态
tailscale status
tailscale ip -4

# 测试与其他组网节点的连通性
tailscale ping <peer-ip>
```

无论平板接入何种网络环境（手机热点、公司内网、家庭 Wi-Fi），只要 Tailscale 在线，均可通过 Tailscale IP 直接进行 SSH 远程连接与各类服务访问。

---

## 4. 下一步

组网建立后，继续配置跨设备生态互联：[KDE Connect 多设备协同](./03-kde-connect.md)。
