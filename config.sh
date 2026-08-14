#!/usr/bin/env bash
#
# config.sh — Optional overrides for organize.sh
#
# This file is sourced by organize.sh if it exists at the path passed
# via -c (default: ./config.sh next to the script). Uncomment and edit
# any of the following to customize behavior. Anything left commented
# out falls back to the built-in defaults in organize.sh.

# Redefine categories and their extensions. Any category you list here
# completely replaces the built-in list of extensions for that category.
# You can also add brand-new categories.
#
# CATEGORY_EXTENSIONS[Images]="jpg jpeg png gif heic"
# CATEGORY_EXTENSIONS[Screenshots]="png"           # example custom category
# CATEGORY_EXTENSIONS[Ebooks]="epub mobi azw3"

# Change the fallback folder name for files that don't match any category.
# DEFAULT_CATEGORY="Misc"
