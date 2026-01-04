# Purpose

Simple script to enumerate all images (jpg/jpeg) in a folder and its subfolders, and then change the modified/created date of the files to match the EXIF originally created date.

The script uses the following priority to determine the date:
1. **EXIF DateTimeOriginal** - from image metadata
2. **Filename pattern** - if filename matches `YYYYMMDD_HHMMSS_*` pattern
3. **Fallback date** - user-provided date (if specified)

## Prerequisites
you need to have `exiftool` installed on your system. In MacOS you can install it using `brew install exiftool`.

## Usage
1. Clone the repository
```bash
git clone <repository-url>
```
2. Change directory to the cloned repository
```bash
cd <repository-name>
```
3. Make the script executable
```bash
chmod +x touch_photo_dates.sh
```
4. Run the script
```bash
./touch_photo_dates.sh [-r] <directory> [fallback_date]
```

### Parameters
- `-r` - **(Optional)** Rename files with EXIF date prefix (`YYYYMMDD_HHMMSS_filename.ext`)
- `<directory>` - **(Required)** Path to the folder containing images to process
- `[fallback_date]` - **(Optional)** A date to use when no EXIF DateTimeOriginal is found. Format: `YYYYMMDD`. The time will be auto-generated in ascending order based on filename (starting at 08:00:00, incrementing by ~1 minute per file).

### Examples
Process images using only EXIF data (updates file modification date):
```bash
./touch_photo_dates.sh /path/to/photos
```

Process images with a fallback date for files missing EXIF data:
```bash
./touch_photo_dates.sh /path/to/photos 20240615
```

Rename files with EXIF date prefix (e.g., `IMG_001.jpg` → `20240615_143022_IMG_001.jpg`):
```bash
./touch_photo_dates.sh -r /path/to/photos
```

Rename files with fallback date for files missing EXIF data:
```bash
./touch_photo_dates.sh -r /path/to/photos 20240615
```
