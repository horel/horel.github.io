---
title: Arch Linux指南
comment: false
categories: ["Linux"]
tags:
  - Linux
sticky: true
date: 2021-04-26 22:50:04
---

# 安装前的准备工作

## 下载镜像

可以去北京外国语(bfsu)大学的镜像站获取最新的iso，地址如下：[广度优先搜索(bfsu)大学开源镜像站](https://mirrors.bfsu.edu.cn/)

## 准备一个U盘

任意品牌，最好是USB3.0以上的，8G就够

## 制作启动盘

win10系统推荐使用rufus软件烧录：[rufus](https://rufus.ie/zh)

linux系统可以直接使用dd命令烧录：

```bash
sudo dd if=Archlinux_name.iso of=/dev/sdb
```

# 基础系统安装
## 确认是否为 UEFI 模式

```bash
ls /sys/firmware/efi/efivars
```
若输出了一堆东西，即 efi 变量，则说明已在 UEFI 模式。否则请确认你的启动方式是否为 UEFI。

## 启动参数修改(optional)

> 若正常启动后花屏,说明显卡驱动有问题(例如NVIDIA显卡太新还没有开源驱动)

启动项按e添加```modprobe.blacklist=nouveau```以禁用开源驱动

## 使用iwd联网

```bash
iwctl
device list
station wlan0 scan
station wlan0 connect "网络名_xxx"
```

## 更新系统时间

```bash
timedatectl set-ntp true
timedatectl status
```

## 分区

我在/dev/nvme0n1这块硬盘上分了四个区

- /boot	分256M	ef00
- swap    分８G        8200
- /            分100G     8304
- /home 分300G     8302

> 使用以下命令分区

```bash
lsblk
gdisk /dev/nvme0n1
用d删除旧分区
用n按上面列出的新建分区
用w确定并退出
```

> 接下来格式化分区

```bash
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.xfs /dev/nvme0n1p3
mkfs.xfs /dev/nvme0n1p4
```

> 然后挂载分区

```bash
mount /dev/nvme0n1p3 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
mount /dev/nvme0n1p4 /mnt/home
```

## 选择镜像

```bash
vim /etc/pacman.d/mirrorlist
```

最上面填入：

> Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch

## 安装必须软件包

```bash
pacstrap /mnt bash-completion iwd dhcpcd base base-devel linux linux-firmware linux-headers man man-db man-pages texinfo vim xfsprogs ntfs-3g nvidia nvidia-utils nvidia-settings opencl-nvidia
```

## 生成Fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
vim /mnt/etc/fstab
```

## Chroot至新系统

```bash
arch-chroot /mnt
```

## 本地化

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

vim /etc/locale.gen
取消注释zh_CN.UTF-8和en_US.UTF-8

locale-gen

vim /etc/locale.conf
填入LANG=en_US.UTF-8
```

## 网络配置

```bash
vim /etc/hostname
```

填入自己的主机名，例如AORUS

```bash
vim /etc/hosts
```

填入如下，要注意主机名相同

```
127.0.0.1	localhost
::1		localhost
127.0.1.1	AORUS.localdomain	AORUS
```

## 生成Initramfs

```bash
mkinitcpio -P
```

## 设置密码

```bash
passwd
```

## 安装grub

```bash
pacman -Sy grub efibootmgr os-prober
cd ~
mkdir MS
mount /dev/nvme1n1p1 MS

#要注意os_prober已经默认不识别其他系统了
vim /etc/default/grub
最后一行填入GRUB_DISABLE_OS_PROBER=false

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
reboot
```

# 桌面环境安装

## 联网

```bash
systemctl start iwd
dhcpcd
iwctl
station wlan0 connect "网络名_xxx"
```

## 新建用户并授权

```bash
useradd -m -G wheel 用户名(limbo)
EDITOR=vim visudo
取消注释 %wheel ALL=(ALL) ALL
exit
以新用户重新登陆
```

## 安装桌面

> 安装gnome40桌面

```bash
sudo pacman -S xorg gdm gnome gnome-tweaks chrome-gnome-shell
```

## 自启动设置

```bash
sudo systemctl preset-all
sudo systemctl enable gdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
```

## 配置CN源

> vim /etc/pacman .conf
>
> 加入以下内容

[archlinuxcn]

Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch

## pacman配置

> vim /etc/pacman.conf	吃豆人、升级前后对比版本

Color

ILoveCandy

VerbosePkgLists

## 安装常用软件

```bash
sudo pacman -S zsh alacritty git wget typora telegram google-chrome chromium neofetch gcc gdb clang llvm nodejs yarn visual-studio-code-bin
```

## 挂起设置

> vim /etc/fstab 把swap的UUID复制下来

> sudo vim /etc/default/grub	在GRUB_CMDLINE_LINUX_DEFAULT里添加例如如下的UUID
>
> resume=UUID=b184a7a0-a9c4-431c-b0a7-f50bbf052eb5

> sudo vim /etc/mkinitcpio.conf	修改例如如下的内容
>
> HOOKS=(base udev resume autodetect modconf block filesystems keyboard fsck)

# 软件安装配置

## dotfiles

[我个人的dotfiles，请根据自身情况修改](https://github.com/horel/dotfiles.git)

## 配置环境变量

;;;id1 vi .xprofile

填入dotfiles里的系统环境变量

;;;

;;;id1 vi .gitconfig

填入dotfiles里的git环境变量

;;;

;;;id1 vi .yarnrc

填入dotfiles里的yarn环境变量

;;;

## clash代理

> sudo pacman -S clash

> 先运行一下clash下载db文件，下不动可以去dotfiles里捞

> 更新配置文件
>
> cd .config/clash
>
> wget 代理链接 -O config.yaml

> 设置开机自启动
>
> systemctl --user enable clash.service

## 安装Fcitx5输入法

sudo pacman -S fcitx5-im fcitx5-chinese-addons

> 另外 CN 源有词库可用：

sudo pacman -S fcitx5-pinyin-{zhwiki,moegirl}

> 支持qt和gtk安装以下依赖

sudo pacman -S fcitx5-qt fcitx5-gtk

> 主题配置参考：[fcitx5-material-color](https://github.com/hosxy/Fcitx5-Material-Color)，安装完成后直接用dotfiles的配置文件

sudo pacman -S fcitx5-material-color

## fontconfig

> 先在.local/share/font把需要的字体放好，再从dotfiles里捞fontconfig

> 还有以下字体推荐安装：

```bash
sudo pacman -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji ttf-sarasa-gothic ttf-nerd-fonts-symbols-mono ttf-opensans adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts ttf-jetbrains-mono wqy-zenhei
```

## Alacritty终端

安装完成后直接从dotfiles捞配置

## zsh

> 在.config/zsh下捞配置即可

```bash
sudo pacman -S exa
cd plugins
git clone https://github.com/zdharma/fast-syntax-highlighting.git
git clone https://github.com/skywind3000/z.lua.git
git clone https://github.com/zsh-users/zsh-autosuggestions.git
```

> 新建.cache/zsh/history存放记录

## proxychains

```bash
sudo pacman -S proxychains-ng
sudo vim /etc/proxychains.conf
最后填入socks5	127.0.0.1	7891
```

## yarn

> 捞配置文件里	.yarnrc

## neovim

```bash
sudo pacman -S neovim nodejs yarn python python-neovim xsel
nvim :checkhealth不用管ruby(我不用)
```

### plug install

> 安装vim-plug：https://github.com/junegunn/vim-plug

```bash
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

> 捞dotfiles最后 :PlugInstall

### coc.nvim

> CocInstall coc-marketplace
>
> CocList markeyplace
>
> coc-word
>
> coc-tabnine
>
> coc-snippets
>
> coc-pairs
>
> coc-highlight
>
> coc-clangd
>
> coc-java

### coc-java

> 格式化

> vi rc.d/03-plugins-settings.vim 添加函数和快捷键

" Add `:Format` command to format current buffer.

command! -nargs=0 Format :call CocAction('format')

nnoremap<silent> <leader>lf :Format<CR>

> CocCommand java.open.formatter.settings 	(需要打开一个java文件)
>
> https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml 	粘贴进去

### neoformat

> c/cpp格式化
>
> clang-format --dump-config --style="{BasedOnStyle: llvm, IndentWidth: 4}" > .clang-format

> java格式化
>
> ~~sudo pacman -S astyle~~
>
> ~~echo "--style=java" > .astylerc~~
>
> (该方法效果一般，已弃用)

> xml格式化
>
> sudo pacman -S tidy

### highlight

> neovim 0.5版本以后使用nvim-treesitter
>
> https://github.com/nvim-treesitter/nvim-treesitter

:TSInstall {language}

## hexo博客恢复

```bash
yarn global add hexo-cli
cd Blog
yarn
然后deasync这玩意有可能不对，重装它吧......
yarn add deasync
```

## telegram

> 记得登陆之前先把TG的代理设好，TG默认是使用系统代理的

## chrome

### SwitchyOmega

> global	socks5	127.0.0.1	7891

> auto switch
>
> 规则列表规则	global
>
> 默认情景模式	直接连接
>
> AutoProxy
>
> https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/fullgfwlist.acl

### Tampermonkey

> 全放在chrome书签栏里了

## VSCode

> 插件

- One Dark Pro

- Cloudmusic
- cpp全家桶
- java全家桶

> 字体

- 'JetBrains Mono','MesloLGS NF','Sarasa Mono SC','monospace','Droid Sans Mono',  monospace, 'Droid Sans Fallback'
- 控制字体大小 19
- 终端字体大小 16

> 主题

- Window: Title Bar Style
- One Dark Pro

> 键映射	!!用惯了Vim实在习惯不了UpArrow / DownArrow补全!!{.danger}

- "key": "tab"

  "command": "selectNextSuggestion"

-  "key": "shift+tab",
   "command": "selectPrevSuggestion"

## maven

> 设置镜像 vi .m2/settings.xml

```xml
<settings>
    <mirrors>
        <mirror>
            <id>nexus-tencentyun</id>
            <mirrorOf>*</mirrorOf>
            <name>Nexus tencentyun</name>
            <url>
            http://mirrors.cloud.tencent.com/nexus/repository/maven-public/</url>
        </mirror>
    </mirrors>
</settings>
```

## 其他软件

- ImageMagick	安装后可使用display命令
- android-tools    安卓工具包(adb等)

# 美化

>  根据自己喜好来吧，可以参考 https://www.gnome-look.org

## gnome-shell-extensions

- **AppIndicator and KStatusNotifierItem Support** 托盘图标支持
- **ArcMenu**
- **Dash to Panel** 在gnome40上可用
- **Dash to Dock**  暂未更新gnome40
- **Espresso** 小咖啡，记得把它配置里的消息提醒关了
- **Native Window Placement** 缩小托盘图标间距
- **No overview at start-up** 在gnome40上开机不自动overview
- **OpenWeather**
- **Removable Drive Menu** 托盘移除U盘
- **Screenshot Tool**
- **Transparent Top Bar**
- **User Themes**
- **Workspace Indicator** 工作区

## 外观

### 应用程序 & Shell

> aur软件先git clone，cd进入软件目录
>
> makepkg -si

[matcha-sea](https://aur.archlinux.org/packages/matcha-gtk-theme)

### 光标

> aur软件 [xcursor-breeze](https://aur.archlinux.org/packages/xcursor-breeze)

### 图标

> sudo pacman -S papirus-icon-theme

> aur软件 [papirus-folders-git](https://aur.archlinux.org/packages/papirus-folders-git)
>
> papirus-folders -C teal --theme Papirus-Light

### grub

[vimix-grub-theme](https://github.com/vinceliuice/grub2-themes)

```bash
git clone https://github.com/vinceliuice/grub2-themes.git
sudo ./install.sh -b -t vimix -i white
```

# 疑难问题(optional)

## 修gdm和nvidia冲突bug(Fuck NVIDIA!)

> 有个版本内核gdm和nvidia驱动冲突了，会卡gdm黑屏

> 把nvidia启动写进kernel modules，提前启动

```bash
sudo nvim /etc/mkinitcpio.conf
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
sudo nvim /etc/default/grub
内核参数加nvidia-drm.modeset=1
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 更新Chrome后每个网页都崩溃

- 系统设置里开启网络代理，手动
- 或者sudo systemctl disable systemd-resolved(可能会导致DN42域名解析错误等等)