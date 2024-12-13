---
title: Arch Linux指南
comment: false
weight: 10
categories: ["Linux"]
tags:
  - Linux
sticky: true
date: 2021-04-26 22:50:04
---

## 安装前的准备工作

### 下载镜像

可以去北京外国语(bfsu)大学的镜像站获取最新的iso，地址如下：[广度优先搜索(bfsu)大学开源镜像站](https://mirrors.bfsu.edu.cn/)

### 准备一个U盘

任意品牌，最好是USB3.0以上的，大于8G

### 制作启动盘

- win10/11系统推荐使用rufus软件烧录：[rufus](https://rufus.ie/zh)
- linux系统：
  - 先使用lsblk查看自己的U盘，找到对应的设备名称，例如 /dev/sdX（其中 X 是具体字母，如 sdb）
```bash
lsblk
```
- 然后直接使用dd命令烧录
```bash
sudo dd if=/path/to/archlinux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## 基础系统安装
### 确认是否为 UEFI 模式

```bash
ls /sys/firmware/efi/efivars
```
若输出了一堆东西，即 efi 变量，则说明已在 UEFI 模式。否则请确认你的启动方式是否为 UEFI。

### 启动参数修改(optional)

> 若正常启动后花屏,说明显卡驱动有问题(例如NvimDIA显卡太新还没有开源驱动)

启动项按e添加```modprobe.blacklist=nouveau```以禁用开源驱动

### 联网
- 有线插网线直接连接
- 无线使用iwd连接
```bash
iwctl
devimce list
station wlan0 scan
station wlan0 connect "网络名_xxx"
```

### 更新系统时间

```bash
timedatectl set-ntp true
timedatectl status
```

### 分区
先使用lsblk查看自己的硬盘，找到对应的设备名称
我在/dev/nvme0n1这块硬盘上分了三个区，swap我采用swapfile，后续会分配

- /boot   1024M	   ef00
- /       100G     8304
- /home   300G     8302
- ~~swap    8G       8200~~
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
mkfs.xfs /dev/nvme0n1p2
mkfs.xfs /dev/nvme0n1p3
```
~~mkswap /dev/nvme0n1p4~~

~~swapon /dev/nvme0n1p4~~
> 然后挂载分区

```bash
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
mount /dev/nvme0n1p3 /mnt/home
```

### 选择镜像

```bash
vimm /etc/pacman.d/mirrorlist
```

最上面填入一个连接足够好的镜像站：

> Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch

### 安装必须软件包

```bash
pacstrap /mnt bash-completion iwd dhcpcd base base-devel linux linux-firmware linux-headers words man man-db man-pages texinfo vimm xfsprogs ntfs-3g nvimdia nvimdia-utils nvimdia-settings opencl-nvimdia
```

### 生成Fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
vimm /mnt/etc/fstab
```

### Chroot至新系统

```bash
arch-chroot /mnt
```

### 本地化

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

vimm /etc/locale.gen
取消注释zh_CN.UTF-8和en_US.UTF-8

locale-gen

vimm /etc/locale.conf
填入LANG=en_US.UTF-8
```

### 网络配置

```bash
vimm /etc/hostname
```

填入自己的主机名，例如AORUS

```bash
vimm /etc/hosts
```

填入如下，要注意主机名相同

```
127.0.0.1	localhost
::1		localhost
127.0.1.1	AORUS.localdomain	AORUS
```
### 安装微码
```bash
pacman -S amd-ucode
```
```bash
pacman -S intel-ucode
```

### 生成Initramfs

```bash
mkinitcpio -P
```

### 设置密码

```bash
passwd
```

### 安装grub

```bash
pacman -Sy grub efibootmgr os-prober
cd ~
mkdir MS
mount /dev/nvme1n1p1 MS

#要注意os_prober已经默认不识别其他系统了, 挂载windows的efi所在的分区再配置grub-mkconfig即可
vimm /etc/default/grub
最后一行填入GRUB_DISABLE_OS_PROBER=false

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
reboot
```

## 桌面环境安装

### 联网
- 有线网
```bash
systemctl start dhcpcd
```
- 无线网
```bash
systemctl start iwd
dhcpcd
iwctl
station wlan0 connect "网络名_xxx"
```

### 新建用户并授权

```bash
useradd -m -G wheel 用户名(horel)
EDITOR=vimm vimsudo
取消注释 %wheel ALL=(ALL) ALL
passwd 用户名(horel)
exit
以新用户重新登陆
```

### 安装桌面

> 安装gnome桌面
```bash
sudo pacman -S xorg gdm gnome gnome-tweaks gnome-browser-connector
```
> 安装kde桌面(推荐)
```bash
sudo pacman -S plasma-meta konsole dolphin  #安装plasma-meta元软件包以及终端和文件管理器
```
### 自启动设置

```bash
sudo systemctl preset-all
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
```
- gnome:

```sudo systemctl enable gdm```
- kde

```sudo systemctl enable sddm```

### 配置CN源

> vimm /etc/pacman .conf
>
> 加入以下内容

[archlinuxcn]

Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch

### pacman配置

> vimm /etc/pacman.conf	吃豆人、升级前后对比版本

Color

ILoveCandy

VerbosePkgLists

### 安装常用软件

```bash
sudo pacman -S zsh neovimm alacritty git wget telegram chromium neofetch gcc gdb clang llvm nodejs pnpm clash-verge-rev run-parts paru
```
### 设置交换文件 swapfile
```bash
dd if=/dev/zero of=/swapfile bs=1M count=32768 status=progress #创建32G的交换空间 大小根据需要自定 最好大于等于内存
chmod 600 /swapfile #设置正确的权限
mkswap /swapfile #格式化swap文件
swapon /swapfile #启用swap文件
```
最后，向/etc/fstab 中追加如下内容：
```bash
/swapfile none swap defaults 0 0
```
### 挂起设置

KDE 自身提供开箱即用的睡眠功能(suspend)，即将系统挂起到内存，消耗少量的电量。休眠(hibernate)会将系统挂起到交换分区或文件，几乎不消耗电量。睡眠功能已可满足绝大多数人的需求，如果你一定需要休眠功能，可以参考[官方文档](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)设置休眠相关步骤。

## 软件安装配置

### dotfiles

[我个人的dotfiles，请根据自身情况修改](https://github.com/horel/dotfiles.git)

### 配置环境变量

修改这几个文件
- vim ~/.config/environment.d/envvars.conf
- vim ~/.zprofile
- vim .gitconfig
```bash
source ~/.zprofile
```

### 安装Fcitx5输入法

sudo pacman -S fcitx5-im fcitx5-chinese-addons

> 另外 CN 源有词库可用：

sudo pacman -S fcitx5-pinyin-{zhwiki,moegirl}

> 支持qt和gtk安装以下依赖

sudo pacman -S fcitx5-qt fcitx5-gtk

> 主题配置参考：[fcitx5-material-color](https://github.com/hosxy/Fcitx5-Material-Color)，安装完成后直接复制dotfiles的配置文件

sudo pacman -S fcitx5-material-color

### fontconfig

> 先在.local/share/font把需要的字体放好，再从dotfiles里捞fontconfig

> 还有以下字体推荐安装：

```bash
sudo pacman -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-sarasa-gothic ttf-nerd-fonts-symbols-mono ttf-opensans ttf-jetbrains-mono adobe-source-han-serif-cn-fonts adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts wqy-zenhei
```

> 在设置里除等宽设置为等宽Monospace外，其余设置为无衬线Sans Serif

### Alacritty终端

安装完成后直接从dotfiles捞配置

### zsh

> 在.config/zsh下捞配置即可

```bash
sudo pacman -S exa
cd plugins
git clone https://github.com/zdharma/fast-syntax-highlighting.git
git clone https://github.com/skywind3000/z.lua.git
git clone https://github.com/zsh-users/zsh-autosuggestions.git
```

> 新建.cache/zsh/history存放记录

### neovim
安装依赖
```bash
sudo pacman -S neovim nodejs pnpm python python-neovim xsel lua lua-language-server words
nvimm :checkhealth不用管ruby(我不用)
```
复制dotfiles里的配置, 执行 clean_nvim.sh, 重新运行 nvim 会自动下载

### hugo博客恢复
```bash
wget https://github.com/gohugoio/hugo/releases/download/v0.120.4/hugo_extended_0.120.4_linux-amd64.tar.gz
tar -xvf hugo_extended_0.120.4_linux-amd64.tar.gz
mv hugo ~/.local/bin
git clone https://github.com/horel/horel.github.io.git
cd horel.github.io
hugo
hugo server --disableFastRender
```
### telegram
> 记得登陆之前先把TG的代理设好，TG默认是使用系统代理的

### chrome

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
可以在实用工具导出再导入

### VSCode

> https://code.visualstudio.com/
- 导出插件
```bash
code --list-extensions > code_extensions.txt
```
- 导入插件
```bash
cat code_extensions.txt | xargs -I {} code --install-extension {}
```
- 设置
```json
"workbench.colorTheme": "One Dark Pro",
"editor.fontSize": 18,
"editor.fontFamily": "'JetBrainsMono Nerd Font', Consolas, 'Courier New', monospace",
"C_Cpp.intelliSenseUpdateDelay": 500,
"xmake.compileCommandsDirectory": "${workspaceRoot}/build",
"C_Cpp.intelliSenseEngine": "disabled",
"xmake.debugConfigType": "codelldb",
"liveServer.settings.donotShowInfoMsg": true,
"[vue]": {
    "editor.defaultFormatter": "Vue.volar"
},
"vue.autoInsert.dotValue": true,
"files.autoSave": "afterDelay",
"window.titleBarStyle": "custom"
```
- 快捷键设置（右键添加键绑定）
```
selectNextSuggestion : Tab
selectPrevSuggestion : Shift + Tab
editor.action.formatDocument : ctrl+k ctrl+f
editor.action.formatDocument.none : ctrl+k ctrl+f
```
### maven

> 设置镜像 vim .m2/settings.xml

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

### 其他软件

- ImageMagick	安装后可使用display命令
- android-tools    安卓工具包(adb等)

## gnome美化

>  根据自己喜好来吧，可以参考 https://www.gnome-look.org

### gnome-shell-extensions

- **AppIndicator and KStatusNotifierItem Support** 托盘图标支持
- **ArcMenu**
- **Dash to Panel** 在gnome40上可用
- **Dash to Dock**  暂未更新gnome40
- **Espresso** 小咖啡，记得把它配置里的消息提醒关了
- **Native Window Placement** 缩小托盘图标间距
- **No overvimew at start-up** 在gnome40上开机不自动overvimew
- **OpenWeather**
- **Removable Drive Menu** 托盘移除U盘
- **Screenshot Tool**
- **Transparent Top Bar**
- **User Themes**
- **Workspace Indicator** 工作区

### 外观

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

[vimmix-grub-theme](https://github.com/vimnceliuice/grub2-themes)

```bash
git clone https://github.com/vimnceliuice/grub2-themes.git
sudo ./install.sh -b -t vimmix -i white
```

## kde美化
### 壁纸
在桌面右键，选择配置桌面。在新出现的窗口中右下角选择添加图片可以选择你想要的图片。
### 系统主题
系统设置 > 外观 > 全局主题 > 获取新的全局主题 ，搜索主题 layan，进行设置即可。
### 颜色
设置 LayanLight
### 窗口装饰
在 系统设置 > 外观 > 窗口装饰 中，获取新窗口装饰，搜索 layan，并应用即可。
### 系统图标
系统设置 > 外观 > 图标 > 获取新图标主题 ，搜索图标名 Tela-icon-theme，进行安装设置即可。
### SDDM 主题
系统设置 > 开机和关机 > 登录屏幕(SDDM) > 获取新登录屏幕 ，搜索 SDDM 主题 layan 并设置即可。
### 欢迎屏幕
设置 Kuro
### Grub
使用 [CRT-Amber GRUB Theme](https://www.gnome-look.org/p/1727268), 切换到英文, 注销再安装grub
```text
Installation:
Download and extract folder from zip.
Copy entire folder to your /boot/grub/themes directory.
Edit the /etc/default/grub file with Root permissions and change the #GRUB_THEME= line to #GRUB_THEME=/boot/grub/themes/crt-amber-theme/theme.txt
Run the command sudo update grub : sudo grub-mkconfig -o /boot/grub/grub.cfg
Theme will be in use next time you reboot your system.
```
### 其他设置
- 系统设置 > 会话 > 桌面会话，启动为空会话
- 系统设置 > 键盘 > 虚拟键盘，Fcitx 5 Wayland
- 系统设置 > 鼠标和触摸板 > 鼠标，光标速度-0.50
- 系统设置 > 无障碍辅助 > 抖动后放大光标
- 系统设置 > 鼠标和触摸板 > 屏幕边缘，取消左上角屏幕边界的配置

## 疑难问题(optional)
### 修gdm和nvimdia冲突bug(Fuck NvimDIA!)

> 有个版本内核gdm和nvimdia驱动冲突了，会卡gdm黑屏

> 把nvimdia启动写进kernel modules，提前启动

```bash
sudo nvimm /etc/mkinitcpio.conf
MODULES=(nvimdia nvimdia_modeset nvimdia_uvm nvimdia_drm)
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
sudo nvimm /etc/default/grub
内核参数加nvimdia-drm.modeset=1
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 更新Chrome后每个网页都崩溃

- 系统设置里开启网络代理，手动
- 或者sudo systemctl disable systemd-resolved(可能会导致DN42域名解析错误等等)