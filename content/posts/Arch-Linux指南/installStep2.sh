#!/bin/bash

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
lsblk
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

# install NVIDIA driver ?
echo "install NVIDIA driver? [y/n]"
read INSTALL_NVIDIA

if [[ "$INSTALL_NVIDIA" == "y" || "$INSTALL_NVIDIA" == "Y" ]]; then
    echo "installing NVIDIA driver..."
    pacman -S nvidia nvidia-utils nvidia-settings opencl-nvidia --noconfirm
    echo "NVIDIA driver completed"
else
    echo "skip NVIDIA driver"
fi

# Exit chroot environment
echo "Exiting chroot environment..."
# Unmount partitions and reboot
echo "Unmounting all mounted partitions..."

echo "[__TODO__]$ exit"
echo "[__TODO__]$ umount -R /mnt"
echo "[__TODO__]$ reboot"