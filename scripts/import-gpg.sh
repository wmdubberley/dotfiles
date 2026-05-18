#!/usr/bin/env bash
set -euo pipefail

# Finds the GPG key relative to this script's location on the USB drive
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="$SCRIPT_DIR/gpg-william-6B09748DDE4B5B88-2026.asc"

if [ ! -f "$KEY_FILE" ]; then
  echo "ERROR: Key file not found at $KEY_FILE"
  echo "Make sure gpg-william-6B09748DDE4B5B88-2026.asc is in the same folder as this script."
  exit 1
fi

echo "Importing GPG key..."
gpg --import "$KEY_FILE"

echo ""
echo "Setting trust to ultimate..."
echo "6B09748DDE4B5B88:6:" | gpg --import-ownertrust

echo ""
echo "Done. Verifying..."
gpg --list-secret-keys
