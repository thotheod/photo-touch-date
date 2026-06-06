# Purpose

Simple script to enumerate all images (jpg/jpeg) in a folder and its subfolders, and then change the modified/created date of the files to match the EXIF originally created date.

This repository also includes `touch_dates_from_filename.sh`, a separate script for files such as videos where the date is in the filename, for example `VID_20260509_220259_168.mp4`.

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
3. Make the scripts executable
```bash
chmod +x touch_photo_dates.sh
chmod +x touch_dates_from_filename.sh
chmod +x rename_img_like_vid.sh
```
4. Run the script
```bash
./touch_photo_dates.sh [-r] [-l] <directory> [fallback_date]
```

### Parameters
- `-r` - **(Optional)** Rename files with EXIF date prefix (`YYYYMMDD_HHMMSS_filename.ext`)
- `-l` - **(Optional)** Enable detailed logging to both terminal and a log file (saved in the target directory)
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

Process with detailed logging (outputs to terminal and saves log file):
```bash
./touch_photo_dates.sh -l /path/to/photos
```

## Filename-based video/file dates

Use `touch_dates_from_filename.sh` when the date is in the filename. This is useful for video files named like:

```text
VID_20260509_220259_168.mp4
```

The script reads that as:

```text
2026-05-09 22:02:59
```

It then updates both the file created date and modified date.

### Usage

```bash
./touch_dates_from_filename.sh [-n] <folder> [mask]
```

### Parameters

- `-n` - **(Optional)** Dry run. Show what would change without updating files.
- `<folder>` - **(Required)** Directory containing files to process.
- `[mask]` - **(Optional)** Filename mask to match. Default: `VID*`.

### Examples

Preview changes for video files beginning with `VID_`:
```bash
./touch_dates_from_filename.sh -n /path/to/videos 'VID_*.mp4'
```

Apply the changes after checking the dry run:
```bash
./touch_dates_from_filename.sh /path/to/videos 'VID_*.mp4'
```

Process any file beginning with `VID`:
```bash
./touch_dates_from_filename.sh /path/to/videos 'VID*'
```

Process all matching files in the folder and subfolders:
```bash
./touch_dates_from_filename.sh /path/to/videos '*'
```

Keep the mask inside quotes, for example `'VID_*.mp4'`, so the shell passes the mask to the script correctly.

Supported filename patterns include:

- `VID_YYYYMMDD_HHMMSS...`
- `VIDYYYYMMDD_HHMMSS...`
- filenames containing `YYYYMMDD_HHMMSS` or `YYYYMMDD-HHMMSS`
 Rename IMG files like VID files

Use `rename_img_like_vid.sh` to rename `IMG_*` files (or any mask you specify) using the same naming format as Android `VID_` files. The date is read from EXIF (`DateTimeOriginal` / `CreateDate`) and the original filename is preserved at the end.

Example:

```text
IMG_3088.jpg  (EXIF DateTimeOriginal = 2026-05-09 19:37:00)
```

becomes:

```text
VID_20260509_193700_IMG_3088.jpg
```

### Usage

```bash
./rename_img_like_vid.sh [-n] [-p prefix] <folder> [mask]
```

### Parameters

- `-n` - **(Optional)** Dry run. Show what would be renamed without changing anything.
- `-p prefix` - **(Optional)** Prefix to add. Default: `VID_`.
- `<folder>` - **(Required)** Directory containing files to rename.
- `[mask]` - **(Optional)** Filename mask. Default: `IMG*`.

Files that already start with the prefix are skipped, so it is safe to re-run.

### Examples

Preview renaming JPG files starting with `IMG_`:
```bash
./rename_img_like_vid.sh -n /path/to/photos 'IMG_*.jpg'
```

Apply the rename:
```bash
./rename_img_like_vid.sh /path/to/photos 'IMG_*.jpg'
```

Use a different prefix, for example `IMG_`:
```bash
./rename_img_like_vid.sh -p 'IMG_' /path/to/photos 'IMG_*.jpg'
```

Rename any file beginning with `IMG`:
```bash
./rename_img_like_vid.sh /path/to/photos 'IMG*'
```

##
### Output
The script shows progress every 10 files and displays a summary at the end:
```
Found 256 files to process
Processing file 1 of 256...
Processing file 10 of 256...
Processing file 20 of 256...
...

===== Summary =====
Updated with EXIF: 200 files
Updated with filename pattern: 30 files
Updated with fallback date: 20 files
Skipped (no date found): 6 files
Total processed: 256 files
```
