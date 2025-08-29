# Waste

`Waste` is a lightweight "trash basket" script for Unix-like systems. Instead of permanently deleting files with `rm`, this script moves them into a timestamped folder in your home directory (`~/.wastebasket`) so you can safely recover them later if needed.

## Features

- Move files to a timestamped wastebasket instead of deleting.
- List the contents of your wastebasket in a tree format.
- Works with multiple files at once.
- Falls back to `sudo` if necessary to move protected files.

## Installation

Run this command in your terminal to download and set up the script in ~/.local/bin (create the folder if it doesn’t exist):

```bash
mkdir -p ~/.local/bin && curl -sSL https://github.com/leonickl/wastebasket/raw/refs/heads/main/waste.sh -o ~/.local/bin/waste && chmod +x ~/.local/bin/waste
```

(Optional) Make your shell safer by aliasing rm to just echo commands. This prevents accidental deletion and encourages using waste.

```bash
alias rm='echo "[WARN] rm called, use waste instead"'
```

The tree view uses [lsd](https://github.com/lsd-rs/lsd). Please install it seperately.

## Usage

Move files to the wastebasket:

```bash
waste file1 file2 ...
```

List wastebasket contents:

```bash
waste -l
```

## Notes

Files are stored under `~/.wastebasket/YYYY-MM-DD-HH-MM-SS/`.

If a file cannot be moved due to permissions, the script will attempt to use `sudo`.
