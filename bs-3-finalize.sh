#!/usr/bin/env sh

# Exit on any error
set -e

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
  echo "Error: This script must not be run as root." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINUX_TYPE="$(source ${SCRIPT_DIR}/get-os.sh)"

mkdir -p ~/MEGA

# Just in case it was left over from a previous run
rm -f ~/.age/github.token 2>/dev/null || true

# Set the remote URLs for the repositories
echo "Fixing remote URLs for the repositories to use SSH..."
git -C ~/.config/chezmoi remote set-url origin git@github.com:shivros/.chezmoi.git
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:shivros/chez-home.git
git -C ~/Workspaces/shivros/bootstrap-nix remote set-url origin git@github.com:shivros/bootstrap-nix.git

echo "Cloning additional repositories..."

# Clone workspaces repositories
for repo in "deepthought" "cutter-templates" "datagrip"; do
  target_dir="$HOME/Workspaces/shivros/$repo"
  if [ ! -d "$target_dir" ]; then
    git clone "git@github.com:shivros/$repo.git" "$target_dir"
  else
    echo "Directory already exists: $target_dir"
  fi
done

if [ "${LINUX_TYPE}" == "arch" ]; then
  yay -Sy --noconfirm --sudoloop \
    asdf-vm \
    sapling-scm-bin \
    cifs-utils \
    swaync \
    swww \
    grim \
    flameshot-git \
    gruvbox-dark-gtk \
    gruvbox-dark-icons-gtk \
    libnotify \
    hyprland \
    wofi \
    nwg-displays \
    hyprpaper \
    hyprlock \
    hyprpicker \
    hypridle \
    cliphist \
    wl-clipboard \
    cliphist \
    hyprcursor \
    phinger-cursors \
    hyprland-autoname-workspaces \
    hyprpolkitagent \
    waypaper \
    vivaldi \
    pavucontrol \
    obs-studio \
    sublime-text-4 \
    vlc \
    openscad \
    nomacs \
    chromium \
    mullvad-vpn \
    mullvad-browser-bin \
    torbrowser-launcher \
    wev \
    telegram-desktop \
    blender \
    thunderbird \
    espanso-wayland \
    simple-scan \
    wev \
    slack-desktop \
    morgen-bin \
    spotify-launcher \
    dropbox-cli \
    visual-studio-code-bin \
    windsurf \
    cursor-bin \
    peek \
    cheese \
    xarchiver \
    bruno \
    broot \
    remmina \
    bitwarden \
    anki \
    libreoffice-still \
    gimp \
    datagrip \
    lan-mouse \
    blueberry \
    light \
    thunar \
    kdiff3 \
    fcron \
    waybar \
    ledger-live-bin \
    network-manager-applet \
    yubico-authenticator-bin \
    xdg-desktop-portal-hyprland-git \
    xdg-desktop-portal-gtk \
    ttf-sharetech-mono-nerd \
    etcher-bin \
    clipnotify \
    fzf \
    hyprland-autoname-workspaces-git \
    windsurf \
    btop

  # xrdp \
  # gnome-remote-desktop \

  # sudo systemctl enable --now xrdp

  # Check if ASDF config already exists before adding it to the shell
  if [ ! -f ~/.config/nushell/env.nu ] || ! grep -q "asdf-completions=" ~/.config/nushell/env.nu; then
    echo "" >>~/.config/nushell/env.nu
    echo "source ~/.config/nushell/completions/asdf/asdf-completions.nu" >>~/.config/nushell/env.nu
    echo "" >>~/.config/nushell/env.nu
  fi

  for plugin in $(awk '{print $1}' ~/.tool-versions); do
    asdf plugin add "$plugin"
  done
  asdf install

  #  gsettings set org.gnome.desktop.interface gtk-theme gruvbox-dark-gtk
  #  gsettings set org.gnome.desktop.interface icon-theme gruvbox-dark-gtk
  #  gsettings set org.gnome.desktop.interface color-scheme prefer-dark

fi

cd "$SCRIPT_DIR" || {
  echo "Error: Failed to change to script directory" >&2
  exit 1
}
