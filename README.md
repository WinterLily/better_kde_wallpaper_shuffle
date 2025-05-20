# Better KDE Wallpaper Shuffle

## Purpose

`better_kde_wallpaper_shuffle.sh` is a Bash script I wrote to fix a minor annoyance I have with KDE, in that wallpapers on shuffle cannot be force synced between displays, which would normally be fine, but if you have an accent colour picking from your wallpaper, can force your desktop to look completely ass on the rest of your displays.

This script will disable the built-in shuffle and instead handle wallpaper changes manually. It will also ensure that the wallpaper is consistent across all monitors.

It is intended to be run as a cronjob to automate wallpaper changes at regular intervals.

## Features

*   **Random Wallpaper Selection**: Picks a random image (JPG, JPEG, PNG) from a user-defined directory.
*   **Multi-Monitor Consistency**: Applies the selected wallpaper to all desktops/screens managed by Plasma.
*   **Avoids Repeats**: Attempts to not select the currently displayed wallpaper if other images are present in the directory.

## Prerequisites

*   A KDE Plasma desktop environment.
*   `qdbus` command-line tool (usually installed by default with KDE Plasma).
*   A directory containing image files (JPG, JPEG, PNG) to be used as wallpapers.

## Usage

### Setting a New Wallpaper

To set a new random wallpaper from a directory:

```bash
/path/to/better_kde_wallpaper_shuffle.sh /path/to/your/wallpaper_directory
```

### Getting the Current Wallpaper

To fetch the patch of the current wallpaper:

```bash
/path/to/better_kde_wallpaper_shuffle.sh --get
```

### Running as a Cronjob

This is intended to run as a cronjob to automate wallpaper changes at regular intervals, so to set a cronjob just:

```bash
crontab -e
# Add the following line to run the script every 15 minutes:
*/15 * * * * /path/to/better_kde_wallpaper_shuffle.sh /path/to/your/wallpaper_directory > /tmp/better_kde_wallpaper_shuffle.log 2>&1
```
