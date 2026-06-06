#!/usr/bin/env zsh

DRY_RUN=false
while getopts "n" opt; do
  case $opt in
    n) DRY_RUN=true ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1:-}" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 [-n] <folder> [mask]"
  echo "  -n:      Dry run. Show what would change without updating files"
  echo "  folder:  Directory containing files to process"
  echo "  mask:    Optional filename mask, for example '*', 'VID_*.mp4', or 'VID*'"
  echo "           Default: VID*"
  echo ""
  echo "Example: $0 /path/to/videos 'VID_*.mp4'"
  exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool is required. Install it with: brew install exiftool"
  exit 1
fi

FOLDER="$1"
MASK="${2:-VID*}"
COUNT_UPDATED=0
COUNT_SKIPPED=0
COUNT_FAILED=0
CURRENT_FILE=0

extract_datetime_from_filename() {
  local filename="$1"

  if [[ "$filename" =~ ^VID_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
    echo "${match[1]}:${match[2]}:${match[3]} ${match[4]}:${match[5]}:${match[6]}"
    return 0
  fi

  if [[ "$filename" =~ ^VID([0-9]{4})([0-9]{2})([0-9]{2})_?([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
    echo "${match[1]}:${match[2]}:${match[3]} ${match[4]}:${match[5]}:${match[6]}"
    return 0
  fi

  if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2})[_-]([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
    echo "${match[1]}:${match[2]}:${match[3]} ${match[4]}:${match[5]}:${match[6]}"
    return 0
  fi

  return 1
}

count_file="/tmp/touch_dates_from_filename_count_$$"
find "$FOLDER" -type f -name "$MASK" ! -name '._*' | wc -l | tr -d ' ' > "$count_file"
TOTAL_FILES=$(cat "$count_file")
rm -f "$count_file"

echo "Folder: $FOLDER"
echo "Mask: $MASK"
echo "Found $TOTAL_FILES matching files"

find "$FOLDER" -type f -name "$MASK" ! -name '._*' | sort | while read -r file; do
  CURRENT_FILE=$((CURRENT_FILE + 1))
  filename=$(basename "$file")
  datetime=$(extract_datetime_from_filename "$filename")

  if [ -z "$datetime" ]; then
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    echo "Skipped: $file (no date found in filename)"
  else
    formatted_date=$(date -j -f "%Y:%m:%d %H:%M:%S" "$datetime" "+%Y%m%d%H%M.%S" 2>/dev/null)

    if [ -z "$formatted_date" ]; then
      COUNT_FAILED=$((COUNT_FAILED + 1))
      echo "Failed:  $file (invalid date in filename: $datetime)"
    elif [ "$DRY_RUN" = true ]; then
      COUNT_UPDATED=$((COUNT_UPDATED + 1))
      echo "Dry run: $file -> $datetime"
    else
      touch -t "$formatted_date" "$file"
      if exiftool -overwrite_original -P "-FileCreateDate=$datetime" "-FileModifyDate=$datetime" "$file" >/dev/null; then
        COUNT_UPDATED=$((COUNT_UPDATED + 1))
        echo "Updated: $file -> $datetime"
      else
        COUNT_FAILED=$((COUNT_FAILED + 1))
        echo "Failed:  $file"
      fi
    fi
  fi

  echo "$COUNT_UPDATED $COUNT_SKIPPED $COUNT_FAILED" > "/tmp/touch_dates_from_filename_counters_$$"
done

if [ -f "/tmp/touch_dates_from_filename_counters_$$" ]; then
  read COUNT_UPDATED COUNT_SKIPPED COUNT_FAILED < "/tmp/touch_dates_from_filename_counters_$$"
  rm -f "/tmp/touch_dates_from_filename_counters_$$"
fi

echo ""
echo "===== Summary ====="
if [ "$DRY_RUN" = true ]; then
  echo "Would update: $COUNT_UPDATED files"
else
  echo "Updated: $COUNT_UPDATED files"
fi
echo "Skipped: $COUNT_SKIPPED files"
echo "Failed: $COUNT_FAILED files"
echo "Total matched: $TOTAL_FILES files"
