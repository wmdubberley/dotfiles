#!/usr/bin/env bash
# Usage: ./run.sh [host-or-group]   e.g. ./run.sh laptop
#        ./run.sh all               apply everything to all machines
set -euo pipefail

TARGET="${1:-all}"
INVENTORY="ansible/inventory/hosts.yml"

ansible-playbook ansible/playbook.yml \
  -i "$INVENTORY" \
  --limit "$TARGET" \
  "${@:2}"
