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

# Create OpenSCAD libraries directory
mkdir -p ~/.local/share/OpenSCAD/libraries

# Define OpenSCAD repositories to clone
declare -A scad_repos=(
    ["scadlib"]="shivros/scadlib"
    ["BOSL2"]="BelfrySCAD/BOSL2"
    ["cc-scad"]="codefold/cc-scad"
    ["constructive"]="solidboredom/constructive"
    ["bladegen-lib"]="tallakt/bladegen"
)

# Clone OpenSCAD repositories
for dir in "${!scad_repos[@]}"; do
    target_dir="$HOME/.local/share/OpenSCAD/libraries/$dir"
    if [ ! -d "$target_dir" ]; then
        git clone "git@github.com:${scad_repos[$dir]}.git" "$target_dir"
    else
        echo "Directory already exists: $target_dir"
    fi
done

# Create bladegen symlink if it doesn't exist
bladegen_link="$HOME/.local/share/OpenSCAD/libraries/bladegen"
if [ ! -L "$bladegen_link" ]; then
    ln -s ~/.local/share/OpenSCAD/libraries/bladegen-lib/libraries/bladegen "$bladegen_link"
else
    echo "Symlink already exists: $bladegen_link"
fi

cd "$SCRIPT_DIR" || {
  echo "Error: Failed to change to script directory" >&2
  exit 1
}
