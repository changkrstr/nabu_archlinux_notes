# Docker 容器化环境与 iptables 避坑修复

在 ARM64 Linux 平板上运行 Docker 可以方便地部署各类自建服务、编译容器与轻量级应用。

---

## 1. 基础安装与用户组配置

```bash
# 1. 安装 docker
sudo pacman -S docker

# 2. 将当前用户加入 docker 组以获得非 root 免 sudo 权限
sudo usermod -aG docker $USER
```

---

## 2. 核心故障排查：Docker 启动失败与 iptables 报错

初次执行 `sudo systemctl start docker` 时，很多用户会发现服务无法启动，`journalctl -xeu docker` 出现类似报错：

```text
Warning: Extension addrtype revision 0 not supported, missing kernel module?
iptables v1.8.13 (nf_tables): RULE_APPEND failed (No such file or directory): rule in chain PREROUTING
```

### 2.1 故障根本原因深度剖析

1. Arch Linux 默认安装的 `iptables` 实现是基于 `nftables` 兼容层的 `iptables-nft`。
2. Docker 在初始化默认网桥网络（`docker0`）时，调用了带有 `-m addrtype` 扩展模块的 iptables 规则。
3. 在 nft 模式下，该规则要求内核编译并提供 `CONFIG_NFT_COMPAT`（`nft_compat` 模块）。
4. 小米平板 5 当前适配的第三方内核（如 `6.14.11-10-nabu`）**未启用 `CONFIG_NFT_COMPAT`**，但完整支持传统的 **`iptables-legacy`** 模块，导致基于 nft 的兼容调用失败。

---

## 3. 完美解决方案：切换为 iptables-legacy

通过安装 `iptables-legacy` 替换掉 `iptables-nft` 即可彻底解决兼容性问题：

```bash
# 安装 iptables-legacy 替换旧有的 iptables
sudo pacman -S iptables-legacy
```

按终端提示确认替换冲突的包。

随后重置 Docker 服务的失败计数并正常启动：

```bash
# 清除 systemd 失败状态
sudo systemctl reset-failed docker

# 启动并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker
```

检查 Docker 状态与运行验证：

```bash
sudo systemctl status docker
docker info
docker run --rm hello-world
```

---

## 4. 下一步

容器服务运行正常后，继续探索在 ARM64 平板上运行 x86 游戏与 Steam 客户端：[FEX-Emu 编译与 Steam 实测](./03-steam-and-fex.md)。
