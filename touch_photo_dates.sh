#!/usr/bin/env zsh

# Parse flags
RENAME_MODE=false
while getopts "r" opt; do
  case $opt in
    r) RENAME_MODE=true ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$1" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 [-r] <folder> [fallback_date]"
  echo "  -r:            Rename files with EXIF date prefix (YYYYMMDD_HHMMSS_filename.ext)"
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
  
  # Determine the datetime to use
  USE_DATETIME=""
  DATETIME_SOURCE=""
  
  if [ -n "$datetime" ]; then
    USE_DATETIME="$datetime"
    DATETIME_SOURCE="exif"
  else
    # Try to extract datetime from filename pattern YYYYMMDD_HHMMSS_*
    filename=$(basename "$file")
    if [[ "$filename" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})_ ]]; then
      YEAR="${match[1]}"
      MONTH="${match[2]}"
      DAY="${match[3]}"
      HOUR="${match[4]}"
      MIN="${match[5]}"
      SEC="${match[6]}"
      USE_DATETIME="${YEAR}:${MONTH}:${DAY} ${HOUR}:${MIN}:${SEC}"
      DATETIME_SOURCE="filename"
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
      
      USE_DATETIME=$(printf "%s %02d:%02d:%02d" \
        "$(date -j -f "%Y%m%d" "$FALLBACK_DATE" "+%Y:%m:%d")" $HOURS $MINUTES $SECONDS)
      DATETIME_SOURCE="fallback"
    fi
  fi
  
  if [ -n "$USE_DATETIME" ]; then
    # Update file modification date
    formatted_date=$(date -j -f "%Y:%m:%d %H:%M:%S" "$USE_DATETIME" "+%Y%m%d%H%M.%S")
    touch -t "$formatted_date" "$file"
    
    if [ "$RENAME_MODE" = true ]; then
      # Rename file with date prefix
      dir=$(dirname "$file")
      filename=$(basename "$file")
      date_prefix=$(date -j -f "%Y:%m:%d %H:%M:%S" "$USE_DATETIME" "+%Y%m%d_%H%M%S")
      
      # Check if file already has the date prefix pattern
      if [[ ! "$filename" =~ ^[0-9]{8}_[0-9]{6}_ ]]; then
        new_filename="${date_prefix}_${filename}"
        mv "$file" "${dir}/${new_filename}"
        echo "Renamed: $file -> ${dir}/${new_filename}"
      else
        echo "Skipped (already prefixed): $file"
      fi
    else
      case "$DATETIME_SOURCE" in
        exif) echo "Updated (EXIF): $file -> $formatted_date" ;;
        filename) echo "Updated (filename): $file -> $formatted_date" ;;
        fallback) echo "Updated (fallback): $file -> $formatted_date" ;;
      esac
    fi
  else
    echo "No DateTimeOriginal metadata found for: $file"
  fi
done 


# do not echo everything
# - keep counters and at then end write something like "Updated 10 files, skipped 5 files"
# optional flag (i.e. -log) to log detailed output to a log file