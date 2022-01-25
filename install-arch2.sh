#!/bin/bash

USER_NAME="FILL IN"     # User for the machine
FULL_NAME="FILL IN"     # Name for GPG and git
EMAIL_ADDRESS="FILL IN" # Email address for SSH, GPG and git
ROOT_PASSWORD="FILL IN" # Root pasword
USER_PASSWORD="FILL IN" # Password for USER_NAME
EDITOR="nano"           # how it's named in pacman
CPU="AMD"               # AMD or Intel
GPU="AMD"               # AMD, Intel or Nvidia

# Install other useful stuff
echo "##### Installing other useful stuff#####"
pacman -Sy --noconfirm $EDITOR                              # Editors
pacman -S --noconfirm networkmanager network-manager-applet # Networking
pacman -S --noconfirm mtools dosfstools ntfs-3g             # Storage tools
pacman -S --noconfirm man man-db man-pages texinfo          # Documentation
if [ $CPU == "AMD" ]
then
    pacman -S --noconfirm amd-ucode                         # AMD CPU
fi
if [ $GPU == "AMD" ]
then
    pacman -S --noconfirm xf86-video-amdgpu amdvlk          # AMD GPU
fi
if [ $CPU == "Intel" ]
then
    pacman -S --noconfirm intel-ucode                       # Intel CPU
fi
if [ $GPU == "Intel" ]
then
    pacman -S --noconfirm xf86-video-intel vulkan-intel     # Intel GPU
fi
if [ $GPU == "Nvidia" ]
then
    pacman -S --noconfirm nvidia nvidia-utils               # Nvidia GPU
fi
pacman -S --noconfirm mesa                                  # OpenGL
pacman -S --noconfirm dialog                                # Dialogue box

# Setting up the system clock
echo "##### Setting up the system clock #####"
ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
hwclock --systohc

# Generate the locales
echo "##### Generating the locales #####"
sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#fi_FI.UTF-8 UTF-8/fi_FI.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=en_GB.UTF-8 >> /etc/locale.conf

# Set the keyboard layout
echo "##### Setting the keyboard layout #####"
echo KEYMAP=uk >> /etc/vconsole.conf

# Network config
echo "##### Setting up network config #####"
echo Joe-PC >> /etc/hostname
echo "127.0.0.1       localhost"                      >> /etc/hosts
echo "::1             localhost"                      >> /etc/hosts
echo "127.0.1.1       Joe-PC.localdomain      Joe-PC" >> /etc/hosts

# Make sure initramfs is all good
echo "##### Making sure initramfs is all good #####"
mkinitcpio -P

# Set root password
echo "##### Setting root password #####"
(
    echo $ROOT_PASSWORD
    echo $ROOT_PASSWORD
) | passwd

# Set up bootloader
echo "##### Setting up bootloader #####"
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set up users
echo "##### Setting up users #####"
useradd -m -G wheel $USER_NAME
(
    echo $USER_PASSWORD
    echo $USER_PASSWORD
) | passwd $USER_NAME
sed -i 's/\# %wheel ALL=\(ALL\) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# Install more stuff
echo "##### Installing more stuff #####"
pacman -S --noconfirm bluez                                               # Bluetooth
pacman -S --noconfirm xorg                                                # Display server
pacman -S --noconfirm pipewire pipewire-pulse                             # Audio server
pacman -S --noconfirm print-manager cups system-config-printer            # Printer stuff
pacman -S --noconfirm plasma sddm sddm-kcm kdialog xdg-utils xdg-user-dirs packagekit-qt5 breeze-gtk   # Desktop environment (KDE)
pacman -S --noconfirm dolphin bluedevil kcalc konsole krdc freerdp ksysguard skanlite kfind # DE apps
pacman -S --noconfirm docker flatpak python-pip                           # Package managers
pacman -S --noconfirm ttf-liberation noto-fonts noto-fonts-emoji noto-fonts-extra ttf-droid ttf-hanazono ttf-inconsolata ttf-junicode xorg-fonts-cyrillic xorg-fonts-misc # Extra fonts
pacman -S --noconfirm firefox code discord git vlc libreoffice gimp htop meld virtualbox virtualbox-host-modules-arch virtualbox-guest-iso gnupg bitwarden geda-gaf cron wget # Other apps
pacman -S --noconfirm gcc llvm clang libc++ meson rustup                  # Base compilation tools
pacman -S riscv32-elf-binutils riscv32-elf-gdb riscv32-elf-newlib riscv64-elf-binutils riscv64-elf-gcc riscv64-elf-gdb riscv64-elf-newlib riscv64-linux-gnu-binutils riscv64-linux-gnu-gcc riscv64-linux-gnu-gdb riscv64-linux-gnu-glibc spike tinyemu # RISC-V compilation tools
# pacman -S wireless_tools wpa_supplicant # Wifi

# 32 bit 
echo "##### Installing 32-bit packages #####"
sed -z 's|\#\[multilib\]\n\#Include = /etc/pacman\.d/mirrorlist|\[multilib\]\nInclude = /etc/pacman\.d/mirrorlist|' -i /etc/pacman.conf
pacman -Sy --noconfirm wine steam            # Apps
if [ $GPU == "AMD" ]
then
    pacman -S --noconfirm lib32-amdvlk       # AMD
fi
if [ $GPU == "Intel" ]
then
    pacman -S --noconfirm lib32-vulkan-intel # Intel
fi
if [ $GPU == "Nvidia" ]
then
    pacman -S --noconfirm lib32-nvidia-utils # Nvidia
fi

# SSH Config
echo "##### Configuring SSH #####"
(
    echo ""
    echo ""
    echo ""
) | ssh-keygen -t ed25519 -C "$EMAIL_ADDRESS"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# GPG Config
echo "##### Configuring GPG #####"
gpg --list-secret-keys --keyid-format=long
(
    echo ""
    echo "4096"
    echo ""
    echo "y"
    echo "$FULL_NAME"
    echo "$EMAIL_ADDRESS"
    echo "Git GPG key for personal use"
    echo "o"
) | gpg --full-generate-key
GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG | sed -n 4p)

# Set Git Config
echo "##### Configuring git #####"
git config --global user.name "$FULL_NAME"
git config --global user.email "$EMAIL_ADDRESS"
git config --global core.editor "$EDITOR"
git config --global user.signingkey $GPG_KEY
git config --global commit.gpgsign true

# AUR packages
echo "##### Installing AUR packages #####"
mkdir -p /home/joe/Repos/AUR
cd /home/joe/Repos/AUR
# ConvertAll
git clone https://aur.archlinux.org/convertall.git
cd convertall
git pull
makepkg -si --noconfirm
cd ../
# Google Chrome
git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
git pull
makepkg -si --noconfirm
cd ../
# PortMaster
git clone https://github.com/safing/portmaster-packaging.git
cd portmaster-packaging
git pull
cd linux
makepkg -si --noconfirm
cd ../../
# QDirStat
git clone https://aur.archlinux.org/qdirstat.git
cd qdirstat
git pull
makepkg -si --noconfirm
cd ../
# Snap - I prefer to use pacman for most things and flatpak if I need to keep an application isolated, but good to have snap in case its the only option
git clone https://aur.archlinux.org/snapd.git
cd snapd
git pull
makepkg -si --noconfirm
cd ../
# VS Code
git clone https://aur.archlinux.org/visual-studio-code-bin.git
cd visual-studio-code-bin
git pull
makepkg -si --noconfirm
cd ../

# Enable services
echo "##### Enabling services #####"
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm

# Set Xorg keyboard layout
echo "##### Setting Xorg keyboard layout #####"
localectl --no-convert set-x11-keymap gb,fi

# Make sure everything is up to date
echo "##### Updating everything #####"
pacman -Syyu --noconfirm

echo "##### Leaving new installation #####"
exit
