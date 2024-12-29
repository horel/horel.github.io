#!/bin/bash

# Check if the system is in UEFI mode
if [ -d /sys/firmware/efi/efivars ]; then
    echo "The system is in UEFI mode."
else
    echo "The system is in BIOS mode, please ensure it meets the installation requirements."
    exit 1
fi

# Enable network time synchronization
echo "Enabling network time synchronization..."
timedatectl set-ntp true

# Check time synchronization status
echo "Checking time synchronization status:"
timedatectl status

# List current disk partitions
echo "Current disk partition information:"
lsblk

# Prompt user to select target disk
read -p "Please enter the disk name to partition (e.g. /dev/nvme0n1): " DISK

# Check if the disk exists
if [ ! -b "$DISK" ]; then
    echo "Disk $DISK does not exist, please check if the input is correct."
    exit 1
fi

# Launch gdisk to partition the disk
echo "Launching gdisk to partition disk $DISK."
echo "Note:"
echo " 1. Use 'd' to delete old partitions."
echo " 2. Use 'n' to create new partitions as needed."
echo " 3. Use 'w' to write changes and exit."

read -p "Press Enter to continue (Please ensure you understand the consequences of partitioning)..."

# Launch gdisk
gdisk "$DISK"

# Notify user that partitioning is complete
echo "Partitioning is complete. Please check the partition results using 'lsblk' or 'gdisk -l $DISK'."

# Format partitions
echo "Formatting partitions, please ensure the partition names are correct!"

# Format the first partition as FAT32
read -p "Please enter the EFI partition name (e.g. /dev/nvme0n1p1): " EFI_PARTITION
mkfs.fat -F32 "$EFI_PARTITION"
echo "EFI partition $EFI_PARTITION formatted to FAT32."

# Format the second partition as XFS
read -p "Please enter the root partition name (e.g. /dev/nvme0n1p2): " ROOT_PARTITION
mkfs.xfs "$ROOT_PARTITION"
echo "Root partition $ROOT_PARTITION formatted to XFS."

# Format the third partition as XFS
read -p "Please enter the /home partition name (e.g. /dev/nvme0n1p3): " HOME_PARTITION
mkfs.xfs "$HOME_PARTITION"
echo "/home partition $HOME_PARTITION formatted to XFS."

echo "All partitions are formatted, please check the formatting results!"

# Mount root partition
echo "Mounting root partition..."
mount "$ROOT_PARTITION" /mnt
echo "Root partition $ROOT_PARTITION mounted to /mnt."

# Create and mount EFI partition
echo "Creating /mnt/boot directory and mounting EFI partition..."
mkdir -p /mnt/boot
mount "$EFI_PARTITION" /mnt/boot
echo "EFI partition $EFI_PARTITION mounted to /mnt/boot."

# Create and mount /home partition
echo "Creating /mnt/home directory and mounting /home partition..."
mkdir -p /mnt/home
mount "$HOME_PARTITION" /mnt/home
echo "/home partition $HOME_PARTITION mounted to /mnt/home."

echo "All partitions are mounted, please check the mount results."

# Set up software repositories
echo "Setting up Arch Linux software repositories..."
# Edit mirrorlist file
echo "Opening /etc/pacman.d/mirrorlist file to set up mirrors..."
echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "Mirror set to: https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch"
echo "Please check and confirm if the mirror settings are correct."
vim /etc/pacman.d/mirrorlist
echo "Software repository setup completed. Please confirm if the configuration is effective."

# Install necessary packages
echo "Installing necessary packages..."
# Use pacstrap to install packages
pacstrap /mnt bash-completion iwd dhcpcd base base-devel linux linux-firmware linux-headers words man man-db man-pages texinfo vim xfsprogs ntfs-3g 
echo "Package installation completed, please check if the installation is successful."

# Generate fstab file
echo "Generating fstab file..."
# Use genfstab to generate and append to /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab file generated and saved to /mnt/etc/fstab."

# Enter chroot environment
echo "Entering chroot environment..."
# Use arch-chroot to enter /mnt
arch-chroot /mnt
echo "Entered chroot environment, you can now configure the system."
