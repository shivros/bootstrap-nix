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

# Create workspace directories
echo "Creating workspace directories..."
echo "oss shivros scratch" \
  | sed 's/ /\n/g' \
  | xargs -I{} mkdir -p ~/Workspaces/{} || {
    echo "Error: Failed to create workspace directories" >&2
    exit 1
  }

rm -rf ~/.config/chezmoi 2>/dev/null || true

# Clone repositories
echo "Cloning dotfiles repository..."
git clone https://github.com/shivros/.chezmoi.git ~/.config/chezmoi || {
  echo "Error: Failed to clone chezmoi repository" >&2
  exit 1
}

# Create .age directory
echo "Creating .age directory..."
mkdir -p ~/.age/ || {
  echo "Error: Failed to create .age directory" >&2
  exit 1
}

# Check if we need to copy any files from donor system
if [ ! -f ~/.age/chezmoi.txt ] || [ ! -f ~/.age/gh-token.encr ]; then
  # Prompt for donor hostname only if needed
  echo -n "Enter donor hostname for age key retrieval: "
  read -r donor_hostname

  if [ -z "$donor_hostname" ]; then
    echo "Error: Donor hostname cannot be empty" >&2
    exit 1
  fi

  # Only copy age key if it doesn't already exist
  if [ ! -f ~/.age/chezmoi.txt ]; then
    echo "Copying age key from donor system..."
    scp "shiv@${donor_hostname}:.age/chezmoi.txt" ~/.age/chezmoi.txt || {
      echo "Error: Failed to copy age key from donor system" >&2
      exit 1
    }
  else
    echo "Age key already exists, skipping copy..."
  fi

  # Only copy gh token if it doesn't already exist
  if [ ! -f ~/.age/gh-token.encr ]; then
    echo "Copying GitHub token from donor system..."
    scp "shiv@${donor_hostname}:.age/gh-token.encr" ~/.age/gh-token.encr || {
      echo "Error: Failed to copy GitHub token from donor system" >&2
      exit 1
    }
  else
    echo "GitHub token already exists, skipping copy..."
  fi
else
  echo "All required files present, skipping donor system copy..."
fi

# Decrypt the GitHub token
if [ ! -f ~/.age/github.token ]; then
  echo "Decrypting GitHub token..."
  echo "You will be prompted for your laptop encryption passphrase to decrypt the GitHub token"
  
  while true; do
    if age --decrypt -o ~/.age/github.token ~/.age/gh-token.encr 2>age_error.tmp; then
      rm age_error.tmp
      break
    else
      error=$(cat age_error.tmp)
      rm age_error.tmp
      if echo "$error" | grep -q "incorrect passphrase"; then
        echo "Error: Incorrect passphrase. Please try again."
      else
        echo "Error: Failed to decrypt GitHub token" >&2
        exit 1
      fi
    fi
  done
else
  echo "GitHub token already decrypted, skipping..."
fi

echo "Logging in to GitHub..."
gh auth login --with-token < ~/.age/github.token || {
  echo "Error: Failed to login to GitHub" >&2
  exit 1
}

rm -f ~/.age/github.token 2>/dev/null || true

rm -rf ~/.local/share/chezmoi 2>/dev/null || true

GIT_CLONE_PROTECTION_ACTIVE=false gh repo clone shivros/chez-home ~/.local/share/chezmoi || {
  echo "Error: Failed to clone chez-home repository" >&2
  exit 1
}

echo "Applying chezmoi configuration..."
chezmoi apply --force || {
  echo "Error: Failed to apply chezmoi configuration" >&2
  exit 1
}

cd "$SCRIPT_DIR" || {
  echo "Error: Failed to change to script directory" >&2
  exit 1
}
