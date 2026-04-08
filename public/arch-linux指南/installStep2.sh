#!/bin/bash
set -e

# ===============================
# 1. 启动网络
# ===============================
sudo systemctl enable --now dhcpcd
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

# ===============================
# 2. 安装 SSH 并启动
# ===============================
sudo pacman -S --noconfirm openssh
sudo systemctl enable --now sshd

# ===============================
# 3. 创建普通用户 horel 并赋予 sudo 权限
# ===============================
sudo useradd -m -G wheel horel
echo "horel:123456" | sudo chpasswd

# 配置 sudo 权限
sudo sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# 切换到普通用户后继续执行
sudo -i -u horel bash <<'EOF'

# ===============================
# 4. 安装 KDE Plasma 桌面环境
# ===============================
sudo pacman -S --noconfirm plasma-meta konsole dolphin
sudo systemctl enable sddm

# ===============================
# 5. 配置 archlinuxcn 源
# ===============================
sudo bash -c 'cat >> /etc/pacman.conf <<CN
[archlinuxcn]
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/\$arch
CN'
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm paru

# ===============================
# 6. pacman 可视化增强
# ===============================
sudo sed -i '/^#Color/s/^#//' /etc/pacman.conf
sudo sed -i '/^#ILoveCandy/s/^#//' /etc/pacman.conf
sudo sed -i '/^#VerbosePkgLists/s/^#//' /etc/pacman.conf

# ===============================
# 7. 安装常用软件和开发工具
# ===============================
sudo pacman -S --noconfirm \
zsh neovim alacritty git wget telegram chromium neofetch \
gcc gdb clang llvm nodejs pnpm clash-verge-rev run-parts paru

EOF

echo ">>> 用户环境配置完成，请注销或重启进入 KDE Plasma"
