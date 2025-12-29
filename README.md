# Purpose

Simple script to enumerate all images (jpg/jpeg) in a folder and its subfolders, and then change the modified/created date of the files to match the EXIF originally created date.

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
./touch_photo_dates.sh <directory> [fallback_date]
```

### Parameters
- `<directory>` - **(Required)** Path to the folder containing images to process
- `[fallback_date]` - **(Optional)** A date to use when no EXIF DateTimeOriginal is found. Format: `YYYYMMDD`. The time will be auto-generated in ascending order based on filename (starting at 08:00:00, incrementing by ~1 minute per file).

### Examples
Process images using only EXIF data:
```bash
./touch_photo_dates.sh /path/to/photos
```

Process images with a fallback date for files missing EXIF data:
```bash
./touch_photo_dates.sh /path/to/photos 20240615
```
