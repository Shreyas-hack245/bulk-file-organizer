#!/usr/bin/env bash
#
# organize.sh — Bulk file organizer
#
# Scans a source directory and sorts files into category folders
# (Images, Documents, Videos, Audio, Archives, Code, Others) based on
# extension, with optional date-based subfolders, collision-safe
# renaming, dry-run mode, and logging.
#
# Usage:
#   ./organize.sh -s SOURCE_DIR [-t TARGET_DIR] [-c CONFIG_FILE]
#                 [-l LOG_FILE] [-b] [-n] [-v]
#
# Options:
#   -s SOURCE_DIR   Directory to organize (required)
#   -t TARGET_DIR   Where organized folders are created (default: SOURCE_DIR)
#   -c CONFIG_FILE  Path to a category config file (default: ./config.sh)
#   -l LOG_FILE     Path to log file (default: ./organize.log)
#   -b              Also create a date-based subfolder (YYYY-MM) under each category
#   -n              Dry run — show what would happen, don't move anything
#   -v              Verbose output
#   -h              Show this help

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

SOURCE_DIR=""
TARGET_DIR=""
CONFIG_FILE="${SCRIPT_DIR}/config.sh"
LOG_FILE="${SCRIPT_DIR}/organize.log"
DATE_SUBFOLDERS=false
DRY_RUN=false
VERBOSE=false

usage() {
    grep '^#' "${BASH_SOURCE[0]}" | sed -n '2,20p' | sed 's/^# \{0,1\}//'
    exit 1
}

while getopts ":s:t:c:l:bnvh" opt; do
    case "$opt" in
        s) SOURCE_DIR="$OPTARG" ;;
        t) TARGET_DIR="$OPTARG" ;;
        c) CONFIG_FILE="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        b) DATE_SUBFOLDERS=true ;;
        n) DRY_RUN=true ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) echo "Unknown option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: -s SOURCE_DIR is required." >&2
    usage
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: source directory '$SOURCE_DIR' does not exist." >&2
    exit 1
fi

SOURCE_DIR="$(cd -- "$SOURCE_DIR" &>/dev/null && pwd)"
TARGET_DIR="${TARGET_DIR:-$SOURCE_DIR}"
mkdir -p "$TARGET_DIR"

 declare -A CATEGORY_EXTENSIONS=(
    [Images]="jpg jpeg png gif bmp svg webp heic tiff"
    [Documents]="pdf doc docx odt txt rtf md xlsx xls csv ppt pptx"
    [Videos]="mp4 mkv mov avi wmv flv webm"
    [Audio]="mp3 wav flac aac ogg m4a"
    [Archives]="zip tar gz bz2 7z rar xz"
    [Code]="sh py js ts html css c cpp h java go rs json yaml yml"
)
DEFAULT_CATEGORY="Others"

 # and/or DEFAULT_CATEGORY.
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

log() {
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] $msg" >> "$LOG_FILE"
    if $VERBOSE; then
        echo "$msg"
    fi
}

 category_for_ext() {
    local ext_lower="$1"
    local cat exts e
    for cat in "${!CATEGORY_EXTENSIONS[@]}"; do
        exts="${CATEGORY_EXTENSIONS[$cat]}"
        for e in $exts; do
            if [[ "$e" == "$ext_lower" ]]; then
                echo "$cat"
                return 0
            fi
        done
    done
    echo "$DEFAULT_CATEGORY"
}

 resolve_collision() {
    local dest_dir="$1"
    local filename="$2"
    local base ext candidate n=1

    if [[ "$filename" == *.* ]]; then
        base="${filename%.*}"
        ext=".${filename##*.}"
    else
        base="$filename"
        ext=""
    fi

    candidate="${dest_dir}/${filename}"
    while [[ -e "$candidate" ]]; do
        candidate="${dest_dir}/${base} (${n})${ext}"
        n=$((n + 1))
    done
    echo "$candidate"
}

moved_count=0
skipped_count=0

log "=== Run started. source=$SOURCE_DIR target=$TARGET_DIR dry_run=$DRY_RUN ==="

while IFS= read -r -d '' file; do
    filename="$(basename -- "$file")"

     case "$filename" in
        organize.log|config.sh) continue ;;
    esac

    if [[ "$filename" == *.* && "$filename" != .* ]]; then
        ext="${filename##*.}"
        ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    else
        ext_lower=""
    fi

    category="$(category_for_ext "$ext_lower")"
    dest_dir="${TARGET_DIR}/${category}"

    if $DATE_SUBFOLDERS; then
        month="$(date -r "$file" '+%Y-%m' 2>/dev/null || date '+%Y-%m')"
        dest_dir="${dest_dir}/${month}"
    fi

    dest_path="$(resolve_collision "$dest_dir" "$filename")"

    if $DRY_RUN; then
        log "[DRY RUN] Would move: $file -> $dest_path"
        moved_count=$((moved_count + 1))
        continue
    fi

    mkdir -p "$dest_dir"
    if mv -- "$file" "$dest_path"; then
        log "Moved: $file -> $dest_path"
        moved_count=$((moved_count + 1))
    else
        log "FAILED to move: $file"
        skipped_count=$((skipped_count + 1))
    fi
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)

log "=== Run finished. moved=$moved_count skipped=$skipped_count ==="
echo "Done. See $LOG_FILE for details."
