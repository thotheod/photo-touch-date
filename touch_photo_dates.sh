#!/usr/bin/env zsh

if [ -z "$1" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 <folder> [fallback_date]"
  echo "  folder:        Directory containing images to process"
  echo "  fallback_date: Optional. Format: 'YYYYMMDD' (used when no EXIF date found)"
  echo "                 Time will be auto-generated ascending based on filename"
  exit 1
fi

FOLDER="$1"
FALLBACK_DATE="$2"

# Validate fallback date format if provided
if [ -n "$FALLBACK_DATE" ]; then
  if ! date -j -f "%Y%m%d" "$FALLBACK_DATE" "+%Y%m%d" >/dev/null 2>&1; then
    echo "Error: Invalid fallback_date format. Use 'YYYYMMDD'"
    exit 1
  fi
fi

# Counter for generating ascending times
TIME_COUNTER=0

find "$FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) \
  ! -name '._*' | sort | while read -r file; do
  datetime=$(exiftool -s3 -DateTimeOriginal "$file")
  if [ -n "$datetime" ]; then
    formatted_date=$(date -j -f "%Y:%m:%d %H:%M:%S" "$datetime" "+%Y%m%d%H%M.%S")
    touch -t "$formatted_date" "$file"
    echo "Updated: $file -> $formatted_date"
  elif [ -n "$FALLBACK_DATE" ]; then
    # Generate ascending time starting from 08:00:00, incrementing by 1 minute per file
    HOURS=$(( 8 + (TIME_COUNTER / 60) ))
    MINUTES=$(( TIME_COUNTER % 60 ))
    SECONDS=$(( (TIME_COUNTER * 7) % 60 ))  # Add some variation to seconds
    TIME_COUNTER=$((TIME_COUNTER + 1))
    
    # Ensure we don't exceed 23:59:59
    if [ $HOURS -gt 23 ]; then
      HOURS=23
      MINUTES=59
      SECONDS=59
    fi
    
    GENERATED_TIME=$(printf "%02d%02d.%02d" $HOURS $MINUTES $SECONDS)
    formatted_date="${FALLBACK_DATE}${GENERATED_TIME}"
    touch -t "$formatted_date" "$file"
    echo "Updated (fallback): $file -> $formatted_date"
  else
    echo "No DateTimeOriginal metadata found for: $file"
  fi
done 


# do not echo everything
# - keep counters and at then end write something like "Updated 10 files, skipped 5 files"
# optional flag (i.e. -log) to log detailed output to a log file