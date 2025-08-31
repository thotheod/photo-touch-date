#!/usr/bin/env zsh

if [ -z "$1" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 <folder>"
  exit 1
fi

find "$1" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) \
  ! -name '._*' | while read -r file; do
  datetime=$(exiftool -s3 -DateTimeOriginal "$file")
  if [ -n "$datetime" ]; then
    formatted_date=$(date -j -f "%Y:%m:%d %H:%M:%S" "$datetime" "+%Y%m%d%H%M.%S")
    touch -t "$formatted_date" "$file"
    echo "Updated: $file -> $formatted_date"
  else
    echo "No DateTimeOriginal metadata found for: $file"
  fi
done


# do not echo everything
# - keep counters and at then end write something like "Updated 10 files, skipped 5 files"
# optional flag (i.e. -log) to log detailed output to a log file