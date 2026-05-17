#!/usr/bin/env bash
set -euo pipefail

# When run via curl | bash, stdin is the pipe not the terminal.
# Redirect stdin to the terminal so read prompts work correctly.
exec < /dev/tty

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/wmdubberley/dotfiles.git}"
PASS_REPO="${PASS_REPO:-https://github.com/wmdubberley/pass-store.git}"

# ── Step 1: Base dependencies ─────────────────────────────────────────────────
echo "[1/7] Installing base dependencies..."
sudo apt-get update -qq
sudo apt-get install -y git curl gpg pass ansible unzip wget

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
git clone "$PASS_REPO" ~/.password-store
echo "  Pass store cloned."

# ── Step 4: Machine type ──────────────────────────────────────────────────────
echo ""
echo "[4/7] Select machine type"
echo "  1) workstations  (desktop/laptop — full GUI + dev tools)"
echo "  2) servers       (headless — docker, kubectl, CLI tools)"
echo "  3) minimal       (CLI only — zsh, git, OCI CLI, VSCode)"
read -rp "  Choice [1-3]: " MACHINE_TYPE_NUM
case $MACHINE_TYPE_NUM in
  2) MACHINE_GROUP="servers" ;;
  3) MACHINE_GROUP="minimal" ;;
  *) MACHINE_GROUP="workstations" ;;
esac
echo "  Machine group: $MACHINE_GROUP"

# ── Step 5: Git identity for this machine ─────────────────────────────────────
echo ""
echo "[5/7] Git identity"
read -rp "  Git email for this machine: " GIT_EMAIL
GIT_NAME="William Dubberley"

# ── Step 6: Clone dotfiles + run Ansible ──────────────────────────────────────
echo ""
echo "[6/7] Clone dotfiles and run Ansible playbook"
DOTFILES_DIR="$HOME/dotfiles"
git clone "$DOTFILES_REPO" "$DOTFILES_DIR"

# Write a temporary inventory targeting localhost in the chosen group
cat > /tmp/bootstrap_inventory.ini << EOF
[${MACHINE_GROUP}]
localhost ansible_connection=local
EOF

cd "$DOTFILES_DIR"
ansible-playbook ansible/playbook.yml \
  -i /tmp/bootstrap_inventory.ini \
  --ask-become-pass

rm /tmp/bootstrap_inventory.ini

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
