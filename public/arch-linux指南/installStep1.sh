#!/bin/bash
set -e

# ===============================
# 0. 更新系统时间
# ===============================
echo ">>> 更新系统时间"
timedatectl set-ntp true

# ===============================
# 1. 分区 (UEFI)
# /boot 1024M ef00
# /      300G 8304
# /home 剩余 8302
# ===============================
DISK="/dev/nvme0n1"

echo ">>> 分区 $DISK"
sgdisk --zap-all $DISK
sgdisk -n 1:0:+1024M -t 1:ef00 -c 1:"EFI System" $DISK
sgdisk -n 2:0:+300G   -t 2:8304 -c 2:"Linux root x86-64" $DISK
sgdisk -n 3:0:0       -t 3:8302 -c 3:"Linux home" $DISK
partprobe $DISK

# ===============================
# 2. 格式化分区
# ===============================
echo ">>> 格式化分区"
mkfs.fat -F32 /dev/nvme0n1p1     # /boot
mkfs.xfs -f /dev/nvme0n1p2       # /
mkfs.xfs -f /dev/nvme0n1p3       # /home

# ===============================
# 3. 挂载分区
# ===============================
echo ">>> 挂载分区"
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
mkdir /mnt/home
mount /dev/nvme0n1p3 /mnt/home

# ===============================
# 4. 设置镜像源 BFSU
# ===============================
echo ">>> 设置 BFSU 镜像源"
sed -i '1i Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist

# ===============================
# 5. 安装基础系统及软件包
# ===============================
echo ">>> 安装基础系统"
pacstrap /mnt \
  bash-completion \
  iwd \
  dhcpcd \
  base base-devel \
  linux linux-firmware linux-headers \
  words man man-db man-pages texinfo \
  vim \
  xfsprogs ntfs-3g \
  nvidia nvidia-utils nvidia-settings opencl-nvidia

# ===============================
# 6. 生成 fstab
# ===============================
echo ">>> 生成 fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# ===============================
# 7. chroot 进入新系统进行配置
# ===============================
arch-chroot /mnt /bin/bash <<'EOF'
set -e

echo ">>> 设置时区"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

echo ">>> 配置 locale"
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ">>> 设置主机名"
echo "REZE" > /etc/hostname

echo ">>> 配置 hosts"
cat >> /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   REZE.localdomain REZE

echo ">>> 设置 root 密码"
echo "root:123456" | chpasswd

echo ">>> 安装 Intel 微码"
pacman -Sy --noconfirm intel-ucode

echo ">>> 生成 initramfs"
mkinitcpio -P

echo ">>> 安装 GRUB 引导"
pacman -Sy --noconfirm grub efibootmgr

# 安装 GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> 创建 swapfile 16G"
fallocate -l 16G /home/swapfile
chmod 600 /home/swapfile
mkswap /home/swapfile
swapon /home/swapfile
echo "/home/swapfile none swap sw 0 0" >> /etc/fstab

EOF

# ===============================
# 8. 卸载并重启
# ===============================
echo ">>> 卸载分区并重启"
umount -R /mnt
reboot
