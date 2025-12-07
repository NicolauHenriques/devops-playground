#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 DIR" >&2
    exit 2
fi

DIR="$1"

if [ ! -d "$DIR" ]; then
  echo "ERROR: '$DIR' is not a directory or does not exist" >&2
  exit 2
fi

echo "Checking permissions in directory: $DIR"
echo

for path in "$DIR"/*; do
    # Handle case where directory is empty (glob doesn't match anything)
    if [ ! -e "$path" ]; then
        echo "  (no entires in directory)"
        break
    fi


    echo "== $path =="
    ls -ld "$path"

    if [ -r "$path" ]; then
        echo "You CAN read this."
    else
        echo "You CANNOT write to this."
    fi


    if [ -w "$path" ]; then
        echo "You CAN write to this."
    else
        echo "You CANNOT write to this."
    fi


    if [ -x "$path" ]; then
        echo "You CAN execute/traverse this."
    else
        echo "You CANNOT execute/traverse this."
    fi


    echo
done

exit 0