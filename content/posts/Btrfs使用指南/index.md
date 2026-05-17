---
title: "Btrfs使用指南"
comment: false
weight: 0
date: 2026-05-18T00:15:26+08:00
# 由 enableGitInfo 替代
# lastmod: 18000-05-05
# draft: false
# math: true
# featuredImage: ""
# featuredImagePreview: ""
# keywords: [""]
categories: ["Linux"]
tags:
  - Linux
---

## 准备
```bash
sudo pacman -S btrfs-progs grub-btrfs
```

## 分区和格式化
- ```/boot/efi``` EFI分区
- ```/``` 根目录（子卷在同一个 Btrfs 文件系统上）

使用gdisk或其他工具正常分区
假设目标盘为 ```/dev/nvme0n1```

```bash
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L Arch /dev/nvme0n1p2
```

## 创建子卷
```bash
# 挂载顶层创建子卷
mount /dev/nvme0n1p2 /mnt
cd /mnt

btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @swap

cd /
umount /mnt
```

## 挂载子卷
```bash
# 根
mount -o subvol=@,compress=zstd:1,noatime /dev/nvme0n1p2 /mnt

# 创建挂载点并挂载其余子卷
mkdir -p /mnt/{boot/efi,home,.snapshots,swap}

mount -o subvol=@home,compress=zstd:1,noatime /dev/nvme0n1p2 /mnt/home
mount -o subvol=@snapshots,compress=zstd:1,noatime /dev/nvme0n1p2 /mnt/.snapshots
mount -o subvol=@swap,nodatacow /dev/nvme0n1p2 /mnt/swap
mount /dev/nvme0n1p1 /mnt/boot/efi

# 继续标准安装：pacstrap, arch-chroot, 装内核等
```

## Swapfile 创建（进入新系统后）
```bash
# 在 @swap 子卷内（已继承 nodatacow）
sudo truncate -s 0 /swap/swapfile
sudo chattr +C /swap/swapfile
sudo dd if=/dev/zero of=/swap/swapfile bs=1M count=16384 status=progress
sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile
sudo swapon /swap/swapfile
```
在```/etc/fstab```最后一行加入
```bash
/swap/swapfile none swap defaults 0 0
```

## 手动创建快照
```bash
sudo mkdir /.snapshots/root
sudo mkdir /.snapshots/home
sudo btrfs subvolume snapshot / /.snapshots/root/__name__
sudo btrfs subvolume snapshot /home /.snapshots/home/__name__
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 查看快照
```bash
ll /.snapshots
btrfs subvolume list /
```

## 删除旧快照
```bash
sudo btrfs subvolume delete /.snapshots/root/__name__
sudo btrfs subvolume delete /.snapshots/home/__name__
```

## 回滚快照
1. 先在grub里选择进入之前的快照
2. 确认当前运行的快照名
```bash
findmnt -n -o OPTIONS / | grep -oP 'subvol=\K[^,]+'
```
3. 挂载 Btrfs 顶层（subvolid=5）
```bash
sudo mkdir -p /mnt/top
sudo mount -o subvolid=5 /dev/nvme0n1p2 /mnt/top
cd /mnt/top
```
> 现在你能看到所有子卷平铺在这里：@、@home、@snapshots、@swap，以及嵌套在 @snapshots 里的你的快照。

4. 删除旧根，从当前快照重建
```bash
# 可选：删除嵌套子卷
# sudo btrfs subvolume delete /mnt/top/@/var/lib/portables
# sudo btrfs subvolume delete /mnt/top/@/var/lib/machines

# 删除旧的 @
sudo btrfs subvolume delete @

# 从当前运行的快照创建新的可写 @
sudo btrfs subvolume snapshot @snapshots/root/__name__ @

# 卸载顶层，重启
cd /
sudo umount /mnt/top
sudo reboot
```