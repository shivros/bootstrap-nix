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
    defaultLocale = \"ru_RU.UTF-8\";

    extraLocaleSettings = {
      LC_ADDRESS = \"ru_RU.UTF-8\";
      LC_IDENTIFICATION = \"ru_RU.UTF-8\";
      LC_MEASUREMENT = \"ru_RU.UTF-8\";
      LC_MONETARY = \"ru_RU.UTF-8\";
      LC_NAME = \"ru_RU.UTF-8\";
      LC_NUMERIC = \"ru_RU.UTF-8\";
      LC_PAPER = \"ru_RU.UTF-8\";
      LC_TELEPHONE = \"ru_RU.UTF-8\";
      LC_TIME = \"ru_RU.UTF-8\";
      LANGUAGE = \"ru_RU.UTF-8\";
      LC_ALL = \"ru_RU.UTF-8\";
      LC_CTYPE = \"ru_RU.UTF-8\";
      LC_COLLATE = \"ru_RU.UTF-8\";
      LC_MESSAGES = \"ru_RU.UTF-8\";
    };
  };
  "

export HOME_MANAGER_BAK="hmgr.$(date +%Y%m%d%H%M%S).bak"