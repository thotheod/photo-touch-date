# Purpose

Simple script to enumerate all images (jpg/jpeg) in a folder and its subfolders, and then change the modified/created date of the files to match the EXIF originally created date.

## Prerequisites
you need to have `exiftool` installed on your system. In MocOs you can install it using `brew install exiftool`.

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
./touch_photo_dates.sh <directory>
```
