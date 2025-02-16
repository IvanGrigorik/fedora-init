#!/usr/bin/env bash
set -euo pipefail

# Speed up dnf (Fedora only)
sudo echo -e "fastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True" | sudo tee -a /etc/dnf/dnf.conf
sudo dnf autoremove
sudo dnf clean all

# Enable RPM Fusion
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                 https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update System
sudo dnf upgrade --refresh

# Install fontconfigs (optional)
sudo dnf install cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++

# Enable Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Nvidia drivers
if ! lspci | grep NVIDIA ; then
	echo "No Nvidia videocard"
else 
	sudo dnf install akmod-nvidia
	sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service
	sudo sed -i 's/nvidia-drm.modeset=1/nvidia-drm.modeset=0/' /etc/default/grub
	sudo grub2-mkconfig -o /etc/grub2.cfg
	sudo sed -i 's@RUN+="/usr/libexec/gdm-runtime-config set daemon WaylandEnable false"@#&@' /lib/udev/rules.d/61-gdm.rules
fi

# Turn off beap sound
dconf write /org/gnome/desktop/sound/event-sounds "false"

# Fix Varmilo keyboard F keys
sudo echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
sudo dracut --regenerate-all --force

# Install packages
sudo dnf install wl-clipboard neofetch htop alacritty tldr tmux bat zsh cmake ninja-build gcc g++ gnome-tweaks telegram discord
flatpak install flathub com.mattjakeman.ExtensionManager

# Git
# Based on https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup
read -rp "Enter your full name for Git: " git_name
git config --global user.name "$git_name"
read -rp "Enter your Git mail: " git_mail
git config --global user.email "$git_mail"
git config --global core.editor nano
git config --global init.defaultBranch master

# Generate SSH key for GitHub
# Based on https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
read -rp "Enter GitHub mail (press ENTER if your would like to use Git mail): " mail
if [ -z "$mail" ]; then
    mail="$git_mail"
fi
ssh-keygen -t ed25519 -C "$mail"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
wl-copy < ~/.ssh/id_ed25519.pub
echo -e "\033[32mAdd SSH public key to GitHub (it's already in the clipboard)\033[39m"
read -p "$*"  # Pause

# Generate GPG key for GitHub
# Based on https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
gpg --full-generate-key
gpg_id="$(gpg --list-secret-keys --keyid-format=long | grep -o "ed25519/.[A-Z0-9]* " | cut -d "/" -f2)"
gpg --armor --export "$gpg_id" | wl-copy
echo "\033[32mAdd GPG public key to GitHub (it's already in the clipboard)\033[39m"
read -p "$*"  # Pause
git config --global user.signingkey "$gpg_id"
git config --global commit.gpgsign true

# Zsh (Require logout)
sudo chsh -s $(which zsh)

# Install omz
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Alacritty

# Settings

# Add Alt + Shift layout switching
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"

# GNOME Tweaks

# Extensions

# For rgb settings
sudo dnf install automake gcc-c++ qt5-qtbase-devel qt5-linguist hidapi-devel libusbx-devel mbedtls-devel
git clone https://gitlab.com/CalcProgrammer1/OpenRGB
cd OpenRGB
qmake-qt5 OpenRGB.pro
make -j$(nproc)
sudo make install
sudo openrgb
