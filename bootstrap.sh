#!/usr/bin/env bash
set -euo pipefail

# When run via curl | bash, stdin is the pipe not the terminal.
# Redirect stdin to the terminal so read prompts work correctly.
exec < /dev/tty

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/wmdubberley/dotfiles.git}"
PASS_REPO="${PASS_REPO:-https://github.com/wmdubberley/pass-store.git}"

# ── Step 1: Base dependencies ─────────────────────────────────────────────────
echo "[1/7] Installing base dependencies..."
if command -v apt-get &>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y git curl gpg pass ansible unzip wget
elif command -v dnf &>/dev/null; then
  sudo dnf install -y epel-release
  sudo dnf install -y git curl gnupg2 pass ansible unzip wget
else
  echo "ERROR: No supported package manager found (apt/dnf)" && exit 1
fi

# ── Step 2: GPG key restoration ───────────────────────────────────────────────
echo ""
echo "[2/7] GPG key restoration"
echo "  Insert your USB drive and import your GPG private key:"
echo "    gpg --import /media/\$USER/keyfob/gpg-william-6B09748DDE4B5B88-2026.asc"
echo ""
read -rp "  Press ENTER once 'gpg --list-secret-keys' shows your key > "

# ── Step 3: pass store ────────────────────────────────────────────────────────
echo ""
echo "[3/7] Clone pass store"
if [ -d "$HOME/.password-store/.git" ]; then
  echo "  Pass store already exists, pulling latest..."
  git -C "$HOME/.password-store" pull
else
  git clone "$PASS_REPO" ~/.password-store
  echo "  Pass store cloned."
fi

# ── Step 4: Machine type ──────────────────────────────────────────────────────
echo ""
echo "[4/7] Select machine type"
echo "  1) workstations  (desktop/laptop — full GUI + dev tools)"
echo "  2) servers       (headless — docker, kubectl, CLI tools)"
echo "  3) minimal       (CLI only — zsh, git, OCI CLI, VSCode)"
echo "  4) homeservers   (local dev cluster — k3s, Docker, Samba, Portainer)"
read -rp "  Choice [1-4]: " MACHINE_TYPE_NUM
case $MACHINE_TYPE_NUM in
  2) MACHINE_GROUP="servers" ;;
  3) MACHINE_GROUP="minimal" ;;
  4) MACHINE_GROUP="homeservers" ;;
  *) MACHINE_GROUP="workstations" ;;
esac
echo "  Machine group: $MACHINE_GROUP"

# ── Step 5: Git identity ──────────────────────────────────────────────────────
echo ""
echo "[5/7] Git identity"
read -rp "  Git email for this machine: " GIT_EMAIL
GIT_NAME="William Dubberley"

# ── Step 6: Clone dotfiles + run Ansible ──────────────────────────────────────
echo ""
echo "[6/7] Clone dotfiles and run Ansible playbook"
DOTFILES_DIR="$HOME/dotfiles"
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "  Dotfiles already exist, pulling latest..."
  git -C "$DOTFILES_DIR" pull
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

cat > /tmp/bootstrap_inventory.ini << EOF
[${MACHINE_GROUP}]
localhost ansible_connection=local
EOF

# sudo-rs requires an interactive TTY — grant temporary NOPASSWD so Ansible
# doesn't need to prompt. One real interactive sudo prompt here is enough.
echo "  Granting temporary passwordless sudo for Ansible (you will be prompted once)..."
sudo sh -c "echo '${USER} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/bootstrap-temp && chmod 440 /etc/sudoers.d/bootstrap-temp"

cd "$DOTFILES_DIR"
ansible-playbook ansible/playbook.yml -i /tmp/bootstrap_inventory.ini

sudo rm -f /etc/sudoers.d/bootstrap-temp
rm -f /tmp/bootstrap_inventory.ini

# ── Step 7: Configure chezmoi and apply dotfiles ──────────────────────────────
echo ""
echo "[7/7] Apply dotfiles via chezmoi"

mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << EOF
sourceDir = "$DOTFILES_DIR/home"

[data]
  git_email    = "$GIT_EMAIL"
  git_name     = "$GIT_NAME"
  machine_group = "$MACHINE_GROUP"
EOF

~/.local/bin/chezmoi apply

echo ""
echo "========================================"
echo "  Bootstrap complete!"
echo "  Restart your shell:  exec zsh"
echo ""
echo "  Post-install reminders:"
echo "  - Restore SSH keys from USB to ~/.ssh/"
echo "  - If workstation: create ~/.local symlink to storage mount"
echo "    ln -s /mnt/storage/william/.local ~/.local"
echo "========================================"
