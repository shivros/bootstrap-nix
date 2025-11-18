#! /usr/bin/env sh

# Exit on any error
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINUX_TYPE="$(source ${SCRIPT_DIR}/get-os.sh)"
UPGRADE="${UPGRADE:-false}"
export NIXDIR="${NIXDIR:-/etc/nixos}"

# Check if script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Get hostname from command line argument or prompt
export HOSTNAME=$1
if [ -z "$HOSTNAME" ]; then
    echo -n "Enter hostname (default: newnix): "
    read -r hostname
    export HOSTNAME=${HOSTNAME:-newnix}
fi

# Always source the default environment
. "${SCRIPT_DIR}/envs/default.sh"

# Source environment overrides based on hostname
if [ -f "${SCRIPT_DIR}/envs/${HOSTNAME}.sh" ]; then
    . "${SCRIPT_DIR}/envs/${HOSTNAME}.sh"
fi

########################################################
# NixOS
########################################################
if [ "${LINUX_TYPE}" == "nix" ]; then
    # Check if we can access /etc/nixos
    cd "${NIXDIR}" || {
        echo "Failed to change directory to ${NIXDIR}" 1>&2
        exit 1
    }

    mkdir -p home-manager

    # Create backup if it doesn't exist
    if [ ! -f configuration.nix.bak ] && [ -f configuration.nix ]; then
        cp configuration.nix configuration.nix.bak || {
            echo "Failed to create backup of configuration.nix" 1>&2
            exit 1
        }
        echo "Created backup at configuration.nix.bak"
    fi

    # Extract LUKS configuration to new file if it doesn't exist
    if [ ! -f luks-configuration.nix ]; then
        if ! echo "{ config, lib, pkgs, ... }:

    {
    boot.initrd.luks.devices = {" >luks-configuration.nix; then
            echo "Failed to create luks-configuration.nix" 1>&2
            exit 1
        fi

        if ! grep "boot.initrd.luks.devices" configuration.nix | sed 's/^.*devices\./    /' >>luks-configuration.nix; then
            echo "Failed to extract LUKS configuration" 1>&2
            exit 1
        fi

        if ! echo "  };
    }" >>luks-configuration.nix; then
            echo "Failed to complete luks-configuration.nix" 1>&2
            exit 1
        fi

        echo "Created luks-configuration.nix"
    fi

    echo "Processing templates..."
    # Find all .tmpl files and process them with envsubst
    nix-shell -p gettext --run "
        for base_dir in \"${SCRIPT_DIR}/nixos\" \"${SCRIPT_DIR}/envs/${HOSTNAME}\"; do
            if [ -d \"\$base_dir\" ]; then
                for tmpl in \"\$base_dir\"/*.tmpl \"\$base_dir\"/**/*.tmpl \"\$base_dir\"/*.nix \"\$base_dir\"/**/*.nix \"\$base_dir\"/*.sh \"\$base_dir\"/**/*.sh; do
                    if [ -f \"\$tmpl\" ]; then
                        # Extract relative path from base_dir
                        rel_path=\"\$(realpath --relative-to=\${base_dir} \"\$tmpl\")\"
                        rel_dir=\"\$(dirname \"\${rel_path}\")\"
                        is_template=false
                        if [ \"\${tmpl%.tmpl}\" != \"\${tmpl}\" ]; then
                            is_template=true
                        fi

                        filename=\"\$(basename \"\${tmpl%.tmpl}\")\"

                        # Create output path preserving directory structure
                        output_file=\"${NIXDIR}/\${rel_dir}/\${filename}\"
                        # Intentionally remove before checking exclusions - to clean up old files
                        rm -f \"\$output_file\"
                        
                        # Check each exclusion explicitly
                        skip_file=false
                        if [ -n \"\$CONFIG_EXCLUSIONS\" ]; then
                            for exclusion in \$CONFIG_EXCLUSIONS; do
                                if [ \"\$filename\" = \"\$exclusion\" ]; then
                                    skip_file=true
                                    printf 'Skipping Excluded Config:\n\t%s\n' \"\$tmpl\"
                                    break
                                fi
                            done
                        fi
                        
                        if [ \"\$skip_file\" = true ]; then
                            continue
                        fi
                        
                        # Create output directory if it doesn't exist
                        mkdir -p \"${NIXDIR}/\${rel_dir}\"
                        
                        if [ \"\$is_template\" = true ]; then
                            envsubst < \"\$tmpl\" > \"\$output_file\"
                            printf 'Processed Template: \n\t%s \n\t-> %s\n' \"\$tmpl\" \"\$output_file\"
                        else
                            cp \"\$tmpl\" \"\$output_file\"
                            printf 'Processed File: \n\t%s \n\t-> %s\n' \"\$tmpl\" \"\$output_file\"
                        fi
                    else
                        printf 'Skipping: %s\n' \"\$tmpl\"
                    fi
                done
            else
                printf 'Directory not found: %s\n' \"\$base_dir\"
            fi
        done" || {
        echo "Failed to process templates" 1>&2
        exit 1
    }
    echo "Templates processed"

    # Add additional configuration imports
    find "${NIXDIR}" -type f -name "*.nix" | while read -r config_file; do
        basename_file=$(basename "$config_file")
        # Skip specific files and home-manager directory
        if [[ "$basename_file" != "configuration.nix" &&
            "$basename_file" != "flake.nix" &&
            ! "$config_file" =~ /home-manager/ ]]; then
            config_import="\.\/${basename_file}"

            if ! sed -i '/\.\/configuration.nix/a\          '"$config_import" flake.nix; then
                echo "Failed to add $basename_file import" 1>&2
                exit 1
            fi
            echo "Added $basename_file import"
        fi
    done

    if [ "${UPGRADE}" = true ]; then
        echo "Creating backup of flake.lock..."
        mv "${NIXDIR}/flake.lock" "${NIXDIR}/flake.lock.$(date +%Y%m%d).bak" || echo "Failed. Skipping flake.lock backup"
        echo "Upgrading NixOS configuration"
        if ! nixos-rebuild switch --flake .\#${HOSTNAME} --option build-use-sandbox false --option eval-cache false; then
            echo "Failed to rebuild NixOS configuration" 1>&2
            exit 1
        fi
    else
        echo "Rebuilding NixOS configuration"
        if ! nixos-rebuild switch --flake .\#${HOSTNAME} --option build-use-sandbox false; then
            echo "Failed to rebuild NixOS configuration" 1>&2
            exit 1
        fi
    fi

    echo "Successfully completed NixOS configuration update"
fi

########################################################
# Arch Linux
########################################################
if [ "${LINUX_TYPE}" == "arch" ]; then
    echo "Installing dependencies"
    if [ "${UPGRADE}" = true ]; then
        echo "Upgrading Arch Linux packages"
        pacman -Syu --noconfirm
    else
        echo "Installing Arch Linux packages"
    fi
    pacman -S --noconfirm \
        tailscale \
        direnv \
        curl \
        git \
        age \
        github-cli \
        chezmoi \
        tmux \
        ghostty \
        starship \
        nushell \
        atuin \
        neovim \
        python-tabulate \
        python-tomli \
        python-pynvim \
        jq \
        docker \
        docker-compose \
        ttf-sharetech-mono-nerd \
        pinentry \
        bat \
        yay \
        greetd \
        greetd-tuigreet \
        pcsc-tools \
        v4l2loopback-dkms \
        v4l2loopback-utils \
        nix \
        networkmanager \
        mpv \
        nm-connection-editor \
        ffmpeg \
        libsecret \
        base-devel \
        syncthing \
        valkey

    echo "Configuring greetd..."
    # groupadd -r greeter >/dev/null 2>&1 || true
    # useradd -r -g greeter -d /var/lib/greetd -s /sbin/nologin -c "Greeter daemon user" greeter >/dev/null 2>&1 || true
    cp /etc/greetd/config.toml /etc/greetd/config.toml.bak || true
    rm /etc/greetd/config.toml || true
    cp "${SCRIPT_DIR}/arch/greetd.toml" /etc/greetd/config.toml || true

    systemctl disable lightdm || true
    systemctl disable sddm || true
    systemctl disable gdm || true

    systemctl enable --now greetd

    systemctl enable --now docker
    systemctl enable --now nix-daemon
    systemctl enable --now pcscd
    systemctl enable --now valkey

    cp "${SCRIPT_DIR}/arch/99-tailscale.conf" /etc/NetworkManager/conf.d/99-tailscale.conf || true
    systemctl enable --now tailscaled
    tailscale up --ssh

    echo "Handling docker nonsense..."
    getent group docker >/dev/null 2>&1 || groupadd docker
    usermod -aG docker $NIXUSER || true
    # newgrp docker || true # This command starts a new shell, causing nesting. Group changes usually require logout/login anyway.

    echo "Updating shell"
    usermod --shell /usr/bin/nu $NIXUSER || {
        echo "Error: Failed to update shell" >&2
        exit 1
    }
    # Because the above typically fails (silently)
    chsh -s /usr/bin/nu $NIXUSER

    mkdir -p /mnt/nas/Library
    mkdir -p /mnt/nas/Projects
    mkdir -p /mnt/nas/Resources

    if [ -f "${SCRIPT_DIR}/arch/extra-fstab" ]; then
        echo "Processing extra fstab entries..."
        while IFS= read -r line; do
            # Skip empty lines and comments
            if [ -n "$line" ] && [ "${line#\#}" != "$line" ]; then
                continue
            fi

            # Check if the line is already in /etc/fstab
            if ! grep -Fxq "$line" /etc/fstab; then
                echo "$line" >>/etc/fstab
                echo "Added to /etc/fstab: $line"
            else
                echo "Already in /etc/fstab: $line"
            fi
        done <"${SCRIPT_DIR}/arch/extra-fstab"
    else
        echo "No extra fstab file found at ${SCRIPT_DIR}/arch/extra-fstab"
    fi
    systemctl daemon-reload
fi

cd "$SCRIPT_DIR" || {
    echo "Error: Failed to change to script directory" >&2
    exit 1
}
