#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 PATH" >&2
  exit 1
fi

TARGET="$1"

if [ ! -e "$TARGET" ]; then
  echo "ERROR: '$TARGET' does not exist" >&2
  exit 2
fi

echo "== Owner / Group Info for: $TARGET =="
ls -ld "$TARGET"
echo

# Get owner, group and perms from stat
# %U = owner name, %G = group name, %A = permissions in rwxr-xr-x form
read -r owner group perms <<<"$(stat -c '%U %G %A' "$TARGET")"

echo "Owner: $owner"
echo "Group: $group"
echo "Perms: $perms"
echo

current_user="$(id -un)"
current_groups="$(id -Gn)"

echo "Current user:     $current_user"
echo "Current groups:   $current_groups"
echo

role="other"

if [ "$current_user" = "$owner" ]; then
  role="owner"
else
  # Check if the path's group is in your groups
  for g in $current_groups; do
    if [ "$g" = "$group" ]; then
      role="group"
      break
    fi
  done
fi

case "$role" in
  owner)
    echo "You are the OWNER for this path."
    echo "The 'user' permission bits in $perms apply to you."
    ;;
  group)
    echo "You are in the GROUP for this path."
    echo "The 'group' permission bits in $perms apply to you."
    ;;
  other)
    echo "You are treated as OTHER for this path."
    echo "The 'other' permission bits in $perms apply to you."
    ;;
esac

exit 0
