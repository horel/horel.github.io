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
read -p "Please enter the root partition name (e.g. /dev/nvme0n1p2): " ROOT_PARTITION
mount "$ROOT_PARTITION" /mnt
echo "Root partition $ROOT_PARTITION mounted to /mnt."

# Create and mount EFI partition
echo "Creating /mnt/boot directory and mounting EFI partition..."
mkdir -p /mnt/boot
read -p "Please enter the EFI partition name (e.g. /dev/nvme0n1p1): " EFI_PARTITION
mount "$EFI_PARTITION" /mnt/boot
echo "EFI partition $EFI_PARTITION mounted to /mnt/boot."

# Create and mount /home partition
echo "Creating /mnt/home directory and mounting /home partition..."
mkdir -p /mnt/home
read -p "Please enter the /home partition name (e.g. /dev/nvme0n1p3): " HOME_PARTITION
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
pacstrap /mnt bash-completion iwd dhcpcd base base-devel linux linux-firmware linux-headers words man man-db man-pages texinfo vim xfsprogs ntfs-3g nvidia nvidia-utils nvidia-settings opencl-nvidia
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

# Set timezone to Shanghai
echo "Setting timezone to Asia/Shanghai..."
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Update hardware clock
echo "Synchronizing hardware clock..."
hwclock --systohc

# Configure locale.gen
echo "Editing /etc/locale.gen file to enable zh_CN.UTF-8 and en_US.UTF-8..."
vim /etc/locale.gen
# Generate locale
echo "Generating locale..."
locale-gen
# Configure locale.conf to set LANG to en_US.UTF-8
echo "Editing /etc/locale.conf file..."
# Set system language
echo "LANG=en_US.UTF-8" > /etc/locale.conf
vim /etc/locale.conf
echo "Timezone and language settings are complete."

# Set hostname
echo "Setting hostname..."
# Edit /etc/hostname file
echo "Please enter the hostname (e.g. AORUS): "
read HOSTNAME
# Write hostname to /etc/hostname
echo "$HOSTNAME" > /etc/hostname
# Display set hostname
echo "Hostname set to: $HOSTNAME"
# Edit /etc/hosts file
echo "Editing /etc/hosts file..."
# Get hostname
HOSTNAME=$(cat /etc/hostname)
# Write to /etc/hosts file
echo "127.0.0.1    localhost" > /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.1.1    $HOSTNAME.localdomain    $HOSTNAME" >> /etc/hosts
# Display update result
echo "/etc/hosts file updated."
cat /etc/hosts

# Install amd-ucode using pacman
pacman -S amd-ucode --noconfirm
# Run mkinitcpio -P
mkinitcpio -P

# Set root password
echo "Setting root password..."
# Run passwd command to set root password
passwd
echo "Root password set."

# Install GRUB
echo "Installing GRUB, efibootmgr, and os-prober..."
pacman -Sy grub efibootmgr os-prober
# Prompt user for Windows EFI partition
echo "Please enter the Windows EFI partition device name (e.g. /dev/nvme1n1p1):"
read WINDOWS_EFI_PARTITION
# Mount Windows EFI partition
echo "Mounting $WINDOWS_EFI_PARTITION to MS directory..."
cd ~
mkdir MS
mount "$WINDOWS_EFI_PARTITION" MS
# Configure GRUB to enable os-prober
echo "Editing /etc/default/grub file..."
# Add GRUB_DISABLE_OS_PROBER=false at the end of the file
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
vim /etc/default/grub
# Install GRUB bootloader
echo "Installing GRUB to EFI partition..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
# Generate GRUB configuration file
echo "Generating GRUB configuration file..."
grub-mkconfig -o /boot/grub/grub.cfg

# Exit chroot environment
echo "Exiting chroot environment..."
exit

# Unmount partitions and reboot
echo "Unmounting all mounted partitions..."
umount -R /mnt
echo "Rebooting the system..."
reboot
