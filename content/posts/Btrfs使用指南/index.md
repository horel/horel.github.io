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

> 不推荐使用 timeshift 管理 btrfs 快照，可能导致系统挂掉

## Snapper管理快照

### 前期分区规划
| 挂载点  | 文件系统 | 类型 |
| ------  | -------- | ---- |
| /efi    | fat      | esp, boot  |
| /       | btrfs    | root |

假设目标盘为 ```/dev/nvme0n1```
```bash
# 格式化分区
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L Arch /dev/nvme0n1p2

# 创建子卷
mount -t btrfs /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# 创建挂载点并挂载其余子卷
mount -t btrfs -o subvol=/@,compress=zstd /dev/nvme0n1p2 /mnt
mount --mkdir -t btrfs -o subvol=/@home,compress=zstd /dev/nvme0n1p2 /mnt/home
mount --mkdir /dev/nvme0n1p1 /mnt/efi

# 中间的安装与配置环节省略，以下为 arch-chroot 环境

# 安装 grub
grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --bootloader-id=Arch --recheck
ln -s /efi/grub /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
```
> 一定要注意 EFI 和 GRUB 都安装在 /efi 目录下，要在 /boot 下创建 GRUB 的软链接，否则部分软件会报错

### 安装依赖
```bash
sudo pacman -S snapper snap-pac btrfs-assistant grub-btrfs inotify-tools
sudo systemctl enable --now grub-btrfsd
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
reboot
```

### 建立配置
```bash
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo vim /etc/snapper/root/config
sudo vim /etc/snapper/home/config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
接下来解释一下配置选项：
```bash
# 快照可占用的最大空间阈值
SPACE_LIMIT=0.3

# 编号快照
NUMBER_CLEANUP=yes
NUMBER_LIMIT="6"
NUMBER_LIMIT_IMPORTANT="3"

# 时间线快照
TIMELINE_CREATE=yes
TIMELINE_CLEANUP=yes
TIMELINE_LIMIT_HOURLY="0"
TIMELINE_LIMIT_DAILY="0"
TIMELINE_LIMIT_WEEKLY="4"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_QUARTERLY="0"
TIMELINE_LIMIT_YEARLY="0"
```
> 每周自动创建一个快照，保留4周的; 每次执行 pacman 自动创建一对 pre/post 快照，保留3对; 手动创建的快照不会自动清理

### 创建手动快照
```bash
sudo snapper -c root create -d "快照描述"
sudo snapper -c home create -d "快照描述"
```

### 管理快照
- 查看
```bash
sudo snapper -c root list
sudo snapper -c home list
```
- 删除
```bash
sudo snapper -c root delete 数字
sudo snapper -c home delete 数字
```
- 触发自动删除
```bash
sudo systemctl start snapper-cleanup.service
```

### 回滚快照
- btrfs-assistant 图形界面
- btrfs-assistant cli
```bash
sudo btrfs-assistant -l 
sudo btrfs-assistant -r 数字
reboot
```
- snapper
```bash
# 左边的数字6代表要使用的快照
# 右边的数字0代表当前状态
# undochange 回滚立刻生效，故不建议用它回滚 root
sudo snapper -c root undochange 6..0
```

## 手动管理快照(不推荐）
### 准备
```bash
sudo pacman -S btrfs-progs grub-btrfs
```

### 分区和格式化
- ```/boot/efi``` EFI分区
- ```/``` 根目录（子卷在同一个 Btrfs 文件系统上）

使用gdisk或其他工具正常分区
假设目标盘为 ```/dev/nvme0n1```

```bash
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L Arch /dev/nvme0n1p2
```

### 创建子卷
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

### 挂载子卷
```bash
# 根
mount -o subvol=@,compress=zstd /dev/nvme0n1p2 /mnt

# 创建挂载点并挂载其余子卷
mkdir -p /mnt/{boot/efi,home,.snapshots,swap}

mount -o subvol=@home,compress=zstd /dev/nvme0n1p2 /mnt/home
mount -o subvol=@snapshots,compress=zstd /dev/nvme0n1p2 /mnt/.snapshots
mount -o subvol=@swap,nodatacow /dev/nvme0n1p2 /mnt/swap
mount /dev/nvme0n1p1 /mnt/boot/efi

# 继续标准安装：pacstrap, arch-chroot, 装内核等
```

### Swapfile 创建（进入新系统后）
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

### 手动创建快照
```bash
sudo mkdir /.snapshots/root
sudo mkdir /.snapshots/home
sudo btrfs subvolume snapshot / /.snapshots/root/__name__
sudo btrfs subvolume snapshot /home /.snapshots/home/__name__
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 查看快照
```bash
ll /.snapshots
btrfs subvolume list /
```

### 删除旧快照
```bash
sudo btrfs subvolume delete /.snapshots/root/__name__
sudo btrfs subvolume delete /.snapshots/home/__name__
```

### 回滚快照
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