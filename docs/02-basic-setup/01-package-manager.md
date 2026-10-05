# 软件包管理与源配置

初次启动 Arch Linux 后，首要任务是配置高速镜像源以及常用软件仓库。

---

## 1. 配置 pacman 镜像源

编辑 `/etc/pacman.d/mirrorlist`，在文件的最顶端添加国内清华大学镜像源（同时可注释掉其他海外镜像）：

```ini
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo
```

更新软件包索引数据库：

```bash
sudo pacman -Syy
```

---

## 2. 配置 archlinuxcn 软件源

官方仓库地址：[https://repo.archlinuxcn.org](https://repo.archlinuxcn.org)

编辑 `/etc/pacman.conf`，在文件末尾追加以下内容：

```ini
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
```

随后导入 archlinuxcn 的 GPG 密钥环：

```bash
sudo pacman -Sy archlinuxcn-keyring
```

---

## 3. 全系统软件包更新

完成镜像与软件源配置后，执行一次完整的系统更新：

```bash
sudo pacman -Syu
```

---

## 4. 安装 AUR 助手（paru）

AUR（Arch User Repository）拥有海量的用户打包软件。此处以 `paru` 为例进行编译与安装：

```bash
# 安装基础编译依赖
sudo pacman -S --needed base-devel git

# 拉取 paru 源码并构建安装
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

安装完成后，即可使用 `paru <package-name>` 便捷搜索与安装 AUR 中的各类软件。

---

## 5. 下一步

基础软件源就绪后，继续配置用户提权与远程访问：[用户与基础服务配置](./02-user-and-ssh.md)。
