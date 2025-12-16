#!/usr/bin/env bash
set -euo pipefail

echo "== User Info =="
echo "User:     $(whoami)"
echo "UID:      $(id -u)"
echo "GID:      $(id -g)"
echo "Groups:      $(id -Gn)"

# From /etc/passwd (or equivalent)
entry="$(getent passwd "$(whoami)")" || exit 0

IFS=':' read -r _ _ _ _ home shell <<< "$entry"

echo
echo "From passwd entry:"
echo "  Home:   $home"
echo "  Shell:  $shell"