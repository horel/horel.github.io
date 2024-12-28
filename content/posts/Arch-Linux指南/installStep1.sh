#!/bin/bash

# 检查是否为 UEFI 模式
if [ -d /sys/firmware/efi/efivars ]; then
    echo "系统为 UEFI 模式。"
else
    echo "系统为 BIOS 模式，请确保符合安装要求。"
    exit 1
fi

# 启用网络时间同步
echo "正在启用网络时间同步..."
timedatectl set-ntp true

# 检查时间同步状态
echo "检查时间同步状态："
timedatectl status

# 列出当前磁盘分区
echo "当前磁盘分区信息："
lsblk

# 提示用户选择目标磁盘
read -p "请输入需要分区的磁盘名称 (例如 /dev/nvme0n1) : " DISK

# 检查磁盘是否存在
if [ ! -b "$DISK" ]; then
    echo "磁盘 $DISK 不存在，请检查输入是否正确。"
    exit 1
fi

# 启动 gdisk 进行分区
echo "即将启动 gdisk 对磁盘 $DISK 进行分区。"
echo "提示："
echo " 1. 使用 'd' 删除旧分区。"
echo " 2. 使用 'n' 按照需求创建新分区。"
echo " 3. 使用 'w' 写入更改并退出。"

read -p "按回车键继续 (请确保您了解分区操作的后果）..."

# 启动 gdisk
gdisk "$DISK"

# 提示完成分区
echo "分区操作完成。请使用 'lsblk' 或 'gdisk -l $DISK' 检查分区结果。"

# 格式化分区
echo "正在格式化分区，请确保分区名称正确！"

# 格式化第一个分区为 FAT32
read -p "请输入EFI分区名称 (例如 /dev/nvme0n1p1) : " EFI_PARTITION
mkfs.fat -F32 "$EFI_PARTITION"
echo "EFI分区 $EFI_PARTITION 格式化为 FAT32 完成。"

# 格式化第二个分区为 XFS
read -p "请输入根分区名称 (例如 /dev/nvme0n1p2) : " ROOT_PARTITION
mkfs.xfs "$ROOT_PARTITION"
echo "根分区 $ROOT_PARTITION 格式化为 XFS 完成。"

# 格式化第三个分区为 XFS
read -p "请输入/home分区名称 (例如 /dev/nvme0n1p3) : " HOME_PARTITION
mkfs.xfs "$HOME_PARTITION"
echo "/home 分区 $HOME_PARTITION 格式化为 XFS 完成。"

echo "所有分区格式化完成，请检查格式化结果！"

# 挂载根分区
echo "挂载根分区..."
read -p "请输入根分区名称 (例如 /dev/nvme0n1p2) : " ROOT_PARTITION
mount "$ROOT_PARTITION" /mnt
echo "根分区 $ROOT_PARTITION 已挂载到 /mnt。"

# 创建并挂载 EFI 分区
echo "创建 /mnt/boot 目录并挂载 EFI 分区..."
mkdir -p /mnt/boot
read -p "请输入EFI分区名称 (例如 /dev/nvme0n1p1) : " EFI_PARTITION
mount "$EFI_PARTITION" /mnt/boot
echo "EFI 分区 $EFI_PARTITION 已挂载到 /mnt/boot。"

# 创建并挂载 /home 分区
echo "创建 /mnt/home 目录并挂载 /home 分区..."
mkdir -p /mnt/home
read -p "请输入 /home 分区名称 (例如 /dev/nvme0n1p3) : " HOME_PARTITION
mount "$HOME_PARTITION" /mnt/home
echo "/home 分区 $HOME_PARTITION 已挂载到 /mnt/home。"

echo "所有分区挂载完成，请检查挂载结果。"

# 设置软件源
echo "正在设置 Arch Linux 软件源..."
# 编辑镜像源列表
echo "正在打开 /etc/pacman.d/mirrorlist 文件以设置镜像源..."
echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "镜像源已设置为： https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch"
echo "请检查并确认镜像源设置是否正确。"
vim /etc/pacman.d/mirrorlist
echo "软件源设置完成。请确认配置是否生效。"

# 安装必要的软件包
echo "正在安装必要的软件包..."
# 使用 pacstrap 安装软件包
pacstrap /mnt bash-completion iwd dhcpcd base base-devel linux linux-firmware linux-headers words man man-db man-pages texinfo vim xfsprogs ntfs-3g nvidia nvidia-utils nvidia-settings opencl-nvidia
echo "软件包安装完成，请检查安装是否成功。"

# 生成 fstab 文件
echo "正在生成 fstab 文件..."
# 使用 genfstab 生成并追加到 /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab 文件已生成并保存到 /mnt/etc/fstab "

# 进入 chroot 环境
echo "正在进入 chroot 环境..."
# 使用 arch-chroot 进入 /mnt
arch-chroot /mnt
echo "已进入 chroot 环境，可以开始配置系统。"

# 设置时区为上海
echo "正在设置时区为 Asia/Shanghai..."
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 更新硬件时钟
echo "正在同步硬件时钟..."
hwclock --systohc

# 配置 locale.gen
echo "正在编辑 /etc/locale.gen 文件以启用 zh_CN.UTF-8 和 en_US.UTF-8..."
vim /etc/locale.gen
# 生成区域设置
echo "正在生成区域设置..."
locale-gen
# 配置 locale.conf 设置 LANG 为 en_US.UTF-8
echo "正在编辑 /etc/locale.conf 文件..."
# 设置系统语言
echo "LANG=en_US.UTF-8" > /etc/locale.conf
vim /etc/locale.conf
echo "时区和语言设置完成。"

# 设置主机名
echo "正在设置主机名..."
# 编辑 /etc/hostname 文件
echo "请输入主机名 (例如 AORUS) : "
read HOSTNAME
# 写入主机名到 /etc/hostname
echo "$HOSTNAME" > /etc/hostname
# 显示设置的主机名
echo "主机名已设置为： $HOSTNAME"
# 设置 /etc/hosts 文件
echo "正在编辑 /etc/hosts 文件..."
# 获取主机名
HOSTNAME=$(cat /etc/hostname)
# 写入 /etc/hosts 文件
echo "127.0.0.1    localhost" > /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.1.1    $HOSTNAME.localdomain    $HOSTNAME" >> /etc/hosts
# 显示设置结果
echo "/etc/hosts 文件已更新。"
cat /etc/hosts

# 使用 pacman 安装 amd-ucode
pacman -S amd-ucode --noconfirm
# 执行 mkinitcpio -P
mkinitcpio -P

# 设置 root 密码
echo "正在设置 root 用户的密码..."
# 执行 passwd 命令来设置 root 密码
passwd
echo "root 密码已设置完成。"

# 安装grub
echo "正在安装 GRUB、efibootmgr 和 os-prober..."
pacman -Sy grub efibootmgr os-prober
# 提示用户输入 Windows EFI 分区
echo "请输入 Windows EFI 分区的设备名称 (例如 /dev/nvme1n1p1) :"
read WINDOWS_EFI_PARTITION
# 挂载 Windows EFI 分区
echo "正在挂载 $WINDOWS_EFI_PARTITION 到 MS 目录..."
cd ~
mkdir MS
mount "$WINDOWS_EFI_PARTITION" MS
# 配置 GRUB 以启用 os-prober
echo "正在编辑 /etc/default/grub 文件..."
# 在文件末尾添加 GRUB_DISABLE_OS_PROBER=false
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
vim /etc/default/grub
# 安装 GRUB 引导加载器
echo "正在安装 GRUB 到 EFI 分区..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
# 生成 GRUB 配置文件
echo "正在生成 GRUB 配置文件..."
grub-mkconfig -o /boot/grub/grub.cfg

# 退出 chroot 环境
echo "退出 chroot 环境..."
exit

# 卸载分区并重启
echo "正在卸载所有挂载的分区..."
umount -R /mnt
echo "重启系统..."
reboot

