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

echo "Permissions for: $TARGET"
ls -ld "$TARGET"
echo

# Test what *you* can do with this path

if [ -r "$TARGET" ]; then
    echo "You CAN read this."
else
    echo "You CANNOT write to this."
fi

if [ -w "$TARGET" ]; then
  echo "You CAN write to this."
else
  echo "You CANNOT write to this."
fi

if [ -x "$TARGET" ]; then
    echo "You CAN execute/traverse this."
else
    echo "You CANNOT execute/traverse this."
fi


exit 0
