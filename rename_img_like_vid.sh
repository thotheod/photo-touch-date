#!/usr/bin/env zsh

DRY_RUN=false
PREFIX="VID_"
while getopts "np:" opt; do
  case $opt in
    n) DRY_RUN=true ;;
    p) PREFIX="$OPTARG" ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1:-}" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 [-n] [-p prefix] <folder> [mask]"
  echo "  -n:        Dry run. Show what would be renamed without changing anything"
  echo "  -p prefix: Prefix to add (default: 'VID_')"
  echo "  folder:    Directory containing files to rename"
  echo "  mask:      Optional filename mask (default: 'IMG*')"
  echo ""
  echo "Example: $0 /path/to/photos 'IMG_*.jpg'"
  echo "  Renames IMG_3088.jpg with EXIF date 2026-05-09 19:37:00"
  echo "  to VID_20260509_193700_IMG_3088.jpg"
  exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool is required. Install it with: brew install exiftool"
  exit 1
fi

FOLDER="$1"
MASK="${2:-IMG*}"
COUNT_RENAMED=0
COUNT_SKIPPED=0
COUNT_FAILED=0
COUNT_ALREADY_PREFIXED=0

count_file="/tmp/rename_img_like_vid_count_$$"
find "$FOLDER" -type f -name "$MASK" ! -name '._*' | wc -l | tr -d ' ' > "$count_file"
TOTAL_FILES=$(cat "$count_file")
rm -f "$count_file"

echo "Folder: $FOLDER"
echo "Mask: $MASK"
echo "Prefix: $PREFIX"
echo "Found $TOTAL_FILES matching files"

find "$FOLDER" -type f -name "$MASK" ! -name '._*' | sort | while read -r file; do
  dir=$(dirname "$file")
  filename=$(basename "$file")

  # Skip files that already start with the prefix
  if [[ "$filename" == ${PREFIX}* ]]; then
    COUNT_ALREADY_PREFIXED=$((COUNT_ALREADY_PREFIXED + 1))
    echo "Skipped (already prefixed): $file"
    echo "$COUNT_RENAMED $COUNT_SKIPPED $COUNT_FAILED $COUNT_ALREADY_PREFIXED" > "/tmp/rename_img_like_vid_counters_$$"
    continue
  fi

  datetime=$(exiftool -s3 -DateTimeOriginal -CreateDate "$file" | awk 'NF {print; exit}')

  if [ -z "$datetime" ]; then
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    echo "Skipped: $file (no EXIF date)"
  else
    date_prefix=$(date -j -f "%Y:%m:%d %H:%M:%S" "$datetime" "+%Y%m%d_%H%M%S" 2>/dev/null)

    if [ -z "$date_prefix" ]; then
      COUNT_FAILED=$((COUNT_FAILED + 1))
      echo "Failed:  $file (invalid date: $datetime)"
    else
      new_filename="${PREFIX}${date_prefix}_${filename}"
      new_path="${dir}/${new_filename}"

      if [ -e "$new_path" ]; then
        COUNT_FAILED=$((COUNT_FAILED + 1))
        echo "Failed:  $file (target already exists: $new_path)"
      elif [ "$DRY_RUN" = true ]; then
        COUNT_RENAMED=$((COUNT_RENAMED + 1))
        echo "Dry run: $file -> $new_path"
      else
        if mv "$file" "$new_path"; then
          COUNT_RENAMED=$((COUNT_RENAMED + 1))
          echo "Renamed: $file -> $new_path"
        else
          COUNT_FAILED=$((COUNT_FAILED + 1))
          echo "Failed:  $file"
        fi
      fi
    fi
  fi

  echo "$COUNT_RENAMED $COUNT_SKIPPED $COUNT_FAILED $COUNT_ALREADY_PREFIXED" > "/tmp/rename_img_like_vid_counters_$$"
done

if [ -f "/tmp/rename_img_like_vid_counters_$$" ]; then
  read COUNT_RENAMED COUNT_SKIPPED COUNT_FAILED COUNT_ALREADY_PREFIXED < "/tmp/rename_img_like_vid_counters_$$"
  rm -f "/tmp/rename_img_like_vid_counters_$$"
fi

echo ""
echo "===== Summary ====="
if [ "$DRY_RUN" = true ]; then
  echo "Would rename: $COUNT_RENAMED files"
else
  echo "Renamed: $COUNT_RENAMED files"
fi
echo "Already prefixed: $COUNT_ALREADY_PREFIXED files"
echo "Skipped (no date): $COUNT_SKIPPED files"
echo "Failed: $COUNT_FAILED files"
echo "Total matched: $TOTAL_FILES files"
