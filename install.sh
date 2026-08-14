#!/usr/bin/env bash
#
# install.sh — Register organize.sh as a daily cron job.
#
# Usage:
#   ./install.sh -s SOURCE_DIR [-t HH:MM]
#
# Adds a crontab entry that runs organize.sh once a day at the given
# time (default 03:00) against SOURCE_DIR. Safe to re-run: it removes
# any previous entry tagged with the same marker before adding a new one.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MARKER="# bulk-file-organizer"

SOURCE_DIR=""
TIME="03:00"

while getopts ":s:t:h" opt; do
    case "$opt" in
        s) SOURCE_DIR="$OPTARG" ;;
        t) TIME="$OPTARG" ;;
        h)
            echo "Usage: $0 -s SOURCE_DIR [-t HH:MM]"
            exit 0
            ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: -s SOURCE_DIR is required." >&2
    exit 1
fi

hour="${TIME%%:*}"
minute="${TIME##*:}"

cron_line="${minute} ${hour} * * * ${SCRIPT_DIR}/organize.sh -s \"${SOURCE_DIR}\" ${MARKER}"

# Strip any prior entry from this tool, then append the new one.
( crontab -l 2>/dev/null | grep -vF "$MARKER" ; echo "$cron_line" ) | crontab -

echo "Installed cron job: runs daily at $TIME on $SOURCE_DIR"
echo "View with: crontab -l"
echo "Remove with: crontab -l | grep -vF '$MARKER' | crontab -"
