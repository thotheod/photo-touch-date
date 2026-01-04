#!/usr/bin/env zsh

# Parse flags
RENAME_MODE=false
LOG_MODE=false
while getopts "rl" opt; do
  case $opt in
    r) RENAME_MODE=true ;;
    l) LOG_MODE=true ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$1" ] || [ ! -d "$1" ]; then
  echo "Usage: $0 [-r] [-l] <folder> [fallback_date]"
  echo "  -r:            Rename files with EXIF date prefix (YYYYMMDD_HHMMSS_filename.ext)"
  echo "  -l:            Enable detailed logging to terminal and log file"
  echo "  folder:        Directory containing images to process"
  echo "  fallback_date: Optional. Format: 'YYYYMMDD' (used when no EXIF date found)"
  echo "                 Time will be auto-generated ascending based on filename"
  exit 1
fi

FOLDER="$1"
FALLBACK_DATE="$2"

# Setup logging
LOG_FILE=""
if [ "$LOG_MODE" = true ]; then
  LOG_FILE="${FOLDER}/touch_photo_dates_$(date +%Y%m%d_%H%M%S).log"
  echo "Logging to: $LOG_FILE"
fi

# Log function - writes to terminal and log file if LOG_MODE is enabled
log_detail() {
  if [ "$LOG_MODE" = true ]; then
    echo "$1" | tee -a "$LOG_FILE"
  fi
}

# Validate fallback date format if provided
if [ -n "$FALLBACK_DATE" ]; then
  if ! date -j -f "%Y%m%d" "$FALLBACK_DATE" "+%Y%m%d" >/dev/null 2>&1; then
    echo "Error: Invalid fallback_date format. Use 'YYYYMMDD'"
    exit 1
  fi
fi

# Counter for generating ascending times
TIME_COUNTER=0

# Counters for summary
COUNT_EXIF=0
COUNT_FILENAME=0
COUNT_FALLBACK=0
COUNT_SKIPPED=0
COUNT_RENAMED=0
COUNT_ALREADY_PREFIXED=0

# Count total files first
echo "Counting files..."
TOTAL_FILES=$(find "$FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) ! -name '._*' | wc -l | tr -d ' ')
echo "Found $TOTAL_FILES files to process"
log_detail "Found $TOTAL_FILES files to process"

CURRENT_FILE=0
PROGRESS_INTERVAL=10

find "$FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) \
  ! -name '._*' | sort | while read -r file; do
  
  CURRENT_FILE=$((CURRENT_FILE + 1))
  
  # Show progress every PROGRESS_INTERVAL files
  if [ $((CURRENT_FILE % PROGRESS_INTERVAL)) -eq 0 ] || [ "$CURRENT_FILE" -eq 1 ]; then
    echo "Processing file $CURRENT_FILE of $TOTAL_FILES..."
  fi
  
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
        COUNT_RENAMED=$((COUNT_RENAMED + 1))
        log_detail "Renamed: $file -> ${dir}/${new_filename}"
      else
        COUNT_ALREADY_PREFIXED=$((COUNT_ALREADY_PREFIXED + 1))
        log_detail "Skipped (already prefixed): $file"
      fi
    else
      case "$DATETIME_SOURCE" in
        exif)
          COUNT_EXIF=$((COUNT_EXIF + 1))
          log_detail "Updated (EXIF): $file -> $formatted_date"
          ;;
        filename)
          COUNT_FILENAME=$((COUNT_FILENAME + 1))
          log_detail "Updated (filename): $file -> $formatted_date"
          ;;
        fallback)
          COUNT_FALLBACK=$((COUNT_FALLBACK + 1))
          log_detail "Updated (fallback): $file -> $formatted_date"
          ;;
      esac
    fi
  else
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    log_detail "Skipped (no date found): $file"
  fi
  
  # Write counters to temp file for access outside the loop
  echo "$COUNT_EXIF $COUNT_FILENAME $COUNT_FALLBACK $COUNT_SKIPPED $COUNT_RENAMED $COUNT_ALREADY_PREFIXED" > /tmp/touch_photo_counters_$$
done

# Read final counters
if [ -f /tmp/touch_photo_counters_$$ ]; then
  read COUNT_EXIF COUNT_FILENAME COUNT_FALLBACK COUNT_SKIPPED COUNT_RENAMED COUNT_ALREADY_PREFIXED < /tmp/touch_photo_counters_$$
  rm /tmp/touch_photo_counters_$$
fi

# Print summary
echo ""
echo "===== Summary ====="
if [ "$RENAME_MODE" = true ]; then
  echo "Renamed: $COUNT_RENAMED files"
  echo "Already prefixed (skipped rename): $COUNT_ALREADY_PREFIXED files"
else
  echo "Updated with EXIF: $COUNT_EXIF files"
  echo "Updated with filename pattern: $COUNT_FILENAME files"
  echo "Updated with fallback date: $COUNT_FALLBACK files"
fi
echo "Skipped (no date found): $COUNT_SKIPPED files"
echo "Total processed: $TOTAL_FILES files"

if [ "$LOG_MODE" = true ]; then
  echo ""
  echo "Detailed log saved to: $LOG_FILE"
fi