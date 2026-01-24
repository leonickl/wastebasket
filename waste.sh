#!/usr/bin/env bash
# waste.sh - Simple trash/wastebasket system

set -euo pipefail

basket_root="$HOME/.wastebasket"

# If "-l" is provided, list contents and exit
for arg in "$@"; do
    if [ "$arg" = "-l" ] || [ "$arg" = "--list" ]; then
        if command -v lsd >/dev/null 2>&1; then
            lsd --tree --depth=2 "$basket_root"
        else
            ls -R "$basket_root"
        fi
        exit 0
    fi
done

# If no arguments, show usage
if [ "$#" -eq 0 ]; then
    echo """
    Usage:
    =====

    '$(basename "$0") [OPTION]' or '$(basename "$0") [FILE]...'


    Available Options:
    =================

    -l | --list: Lists the current content of the wastebasket using the ls command.
                 If lsd is installed, a tree is printed.
    """
    exit 1
fi

timestamp="$(date +"%Y-%m-%d-%H-%M-%S")"

# Process each file
for item in "$@"; do
    folder="$basket_root/$timestamp"

    # Add counter if the target directory exists
    counter=1
    while [ -d "$folder" ]; do
        folder="$basket_root/${timestamp}_$counter"
        ((counter++))
    done

    if [ ! -e "$item" ]; then
        echo "⚠️  '$item' does not exist, skipping."
        continue
    fi

    mkdir -p "$folder"

    # Try moving regularly and then with sudo
    if mv "$item" "$folder/file" 2>/dev/null; then
        echo "🗑️  Wasted: '$item'"
        echo "$(realpath $item)" >> "$folder/info"
    elif sudo mv "$item" "$folder/file"; then
        echo "🗑️  Wasted (sudo): '$item'"
        echo "$(realpath $item)" >> "$folder/info"
    else
        echo "❌ Failed to move '$item'"
    fi
done
