#!/usr/bin/env bash
# waste.sh - Simple trash/wastebasket system

set -euo pipefail

basket_root="$HOME/.wastebasket"

# If "-l" is provided, list contents and exit
for arg in "$@"; do
    if [ "$arg" = "-l" ] || [ "$arg" = "--list" ]; then
        for dir in $basket_root/*; do
            if [ -e $dir/info ]; then
                echo "$(basename $dir): $(cat $dir/info)"
            else
                echo "$(basename $dir)"
            fi
        done

        exit 0
    fi

    if [ "$arg" = "-u" ] || [ "$arg" = "--undo" ]; then
        # read latest entry
        latest=$(tail -n 1 "$basket_root/.latest")

        # loop over all files that were deleted in this batch
        for file in $basket_root/$latest*; do
            if [ -e $file/file ] && [ -f $file/info ]; then
                source=$(cat $file/info)

                mv $file/file $source
                rm -r $file

                echo "Restored: '$source'"
            else
                echo "Deleted file or corresponding info does not exist."
            fi
        done

        # remove latest entry
        sed -i '$ d' "$basket_root/.latest"

        exit 0
    fi

    if [ "$arg" = "-p" ] || [ "$arg" = "--prune" ]; then
        n=${2:-30}

        n_days_ago=$(date -d "$n days ago" +"%Y%m%d")

        old_files=$(ls $basket_root | awk -F- -v cutoff="$n_days_ago" '$1$2$3 < cutoff {print $1"-"$2"-"$3}' | sort -u)

        for file in $old_files; do
            # try to delete and rm as sudo otherwise
            rm -rf $basket_root/$file* 2>/dev/null || sudo rm -rf $basket_root/$file*
        done

        exit 0
    fi

    if [ "$arg" = "--update" ]; then
        mkdir -p $HOME/.local/bin   

        if [ -f  $HOME/.local/bin/waste ]; then
            rm $HOME/.local/bin/waste
        fi

        curl -sSL \
            https://raw.githubusercontent.com/leonickl/wastebasket/main/waste.sh?blabla=$(date +"%Y-%m-%d-%H-%M-%S") \
            -o $HOME/.local/bin/waste

        chmod +x $HOME/.local/bin/waste

        echo "Updated program"

        exit 0
    fi

    if [ "$arg" = "--self" ]; then
        rm $HOME/.local/bin/waste
        echo "waste wasted waste"
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

    -l | --list:          List the current content of the wastebasket.
    -u | --undo:          Restore recently deleted files.
    -p | --prune [days]:  Delete entries older than a specified number of days (30 by default).
    --update:             Updates the program.
    --self:               Wastes the program executable.

    (c) Leo Nickl 2026
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

echo $timestamp >> "$basket_root/.latest"
