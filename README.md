# bootstrap-nix

## Grab the script

```
mkdir -p ~/Workspaces/shivros/
cd ~/Workspaces/shivros
nix-shell -p git
git clone https://github.com/shivros/bootstrap-nix
cd bootstrap-nix
```

## Run the script to setup the OS

```
su -c './bs-1-setup-os.sh desired-hostname'
```

If something breaks, you can revert to the backup of the config with:

```
sudo ./reset-config.sh
```

## Get a donor for decrypting Chezmoi data

You need a system with the age symmetric keys already in place.

Login to tailscale on the new system:

```
sudo tailscale up --ssh
```

You'll need to use the donor system and type the link manually.

With the system logged in, you can run the script that bootstraps chezmoi.
You'll be prompted for the donor system name and the password used to encrypt the github token on the donor system.

```
./bs-2-setup-home.sh
```

## Run cleanup script

```
./bs-3-finalize.sh
```

Reboot

## Graphics Configuration

https://wiki.nixos.org/wiki/AMD_GPU
https://nixos.wiki/wiki/Nvidia

Place your changes in `/etc/nixos/graphics-configuration.nix`. You can either add the dependency to `configuration.nix` manually or re-run `bs-1-setup-os.sh`, which will automatically add the import if it detects a graphics config.

If you're using a laptop, check if it's optimized here:
https://github.com/NixOS/nixos-hardware

## Misc

### MEGA

Run mega-cmd, which is interactive.

```
mkdir ~/MEGA
mega-cmd
```

Login will prompt for password and 2-factor. Do not copy/paste the password or it will fail.

```
login <email>
```

Add the sync. It needs the full path

```
sync /home/shiv/MEGA/ /
```

### Dropbox

```
dropbox-cli autostart y
dropbox-cli start
```

The `start` command will automatically open your browser to authenticate.

### Firefox

Find Profile Folder:
about:support

Settings:
about:config

#### Enable CSS Styles

Set to true:
toolkit.legacyUserProfileCustomizations.stylesheets

#### Disable search for "go" domain

Set to true:
browser.fixup.dns_first_for_single_words

#### disable search in the search bar

Set to false:
keyword.enabled

#### crontabs

```
*/5 * * * * /home/shiv/.local/bin/auto-commit >> /dev/null 2>&1
```
