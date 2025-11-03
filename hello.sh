#!/usr/bin/env bash
NAME="${1:-friend}"
echo "Hi, ${NAME}. It is $(date)"
echo "Top of your disk report:"
df -h | head -n 5
