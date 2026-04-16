#!/usr/bin/env sh

# User
export NIXUSER="${NIXUSER:-shiv}"

# Hostname
export HOSTNAME="${HOSTNAME:-newnix}"

# Exclude certain configuration files from being auto-imported into flake.nix
export CONFIG_EXCLUSIONS=""

# For setting up specific nixos-hardware imports in flake.nix
export ADDITIONAL_INPUTS=""
# e.g. export ADDITIONAL_INPUTS="nixos-hardware.url = \"nixos-hardware/master\";"
export ADDITIONAL_OUTPUTS=""
# e.g. export ADDITIONAL_OUTPUTS="nixos-hardware"
export ADDITIONAL_MODULES=""
# e.g. export ADDITIONAL_MODULES="nixos-hardware.nixosModules.lenovo-legion-16irx9h"

# System locale
export LOCALE="
  i18n = {
    # Select internationalisation properties.
    defaultLocale = \"en_US.UTF-8\";

    extraLocaleSettings = {
      LC_ADDRESS = \"en_US.UTF-8\";
      LC_IDENTIFICATION = \"en_US.UTF-8\";
      LC_MEASUREMENT = \"en_US.UTF-8\";
      LC_MONETARY = \"en_US.UTF-8\";
      LC_NAME = \"en_US.UTF-8\";
      LC_NUMERIC = \"en_US.UTF-8\";
      LC_PAPER = \"en_US.UTF-8\";
      LC_TELEPHONE = \"en_US.UTF-8\";
      LC_TIME = \"en_US.UTF-8\";
      LANGUAGE = \"en_US.UTF-8\";
      LC_ALL = \"en_US.UTF-8\";
      LC_CTYPE = \"en_US.UTF-8\";
      LC_COLLATE = \"en_US.UTF-8\";
      LC_MESSAGES = \"en_US.UTF-8\";
    };
  };
  "

export HOME_MANAGER_BAK="hmgr.$(date +%Y%m%d%H%M%S).bak"
