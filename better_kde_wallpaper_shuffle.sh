#!/bin/bash

# --- Color Definitions ---
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# --- Logging Function ---
# Usage: log_message LEVEL "Log message"
# LEVEL can be one of:
#  - INFO,
#  - WARN,
#  - ERROR,
#  - SUCCESS
#
log_message() {
    local level="$1"
    local message="$2"
    local color=""
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO) color="$BLUE" ;;
        WARN) color="$YELLOW" ;;
        ERROR) color="$RED" ;;
        SUCCESS) color="$GREEN" ;;
        *) color="$RESET" ;; # Default to no color if level is unknown
    esac

    printf "${timestamp} ${color}[%s]${RESET} %s\n" "$level" "$message"
}

# --- Check to see if we're running on KDE Plasma ---
# Obviously, if we're not running on Plasma this script won't work
#
if ! env | grep -q -E "KDE_FULL_SESSION|DESKTOP_SESSION.*plasma|XDG_CURRENT_DESKTOP.*KDE"; then
  if ! pgrep -x "plasmashell" > /dev/null; then
    log_message "ERROR" "This script is intended to be run within a KDE Plasma session."
    log_message "ERROR" "KDE environment variables not found, and plasmashell process not detected."
    exit 1
  fi
fi

# --- Fetch the current wallpaper ---
# Returns the path of the current wallpaper
#
get_current_wallpaper() {
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'string:
var Desktops = desktops();
if (Desktops.length > 0) {
    var d = Desktops[0];
    d.currentConfigGroup = Array("Wallpaper",
                               "org.kde.image",
                               "General");
    print(d.readConfig("Image"));
} else {
    print("");
}
'
}

# --- Set a new wallpaper ---
# Sets the wallppaer at random given the file path of a
# folder that has some images in it
set_new_wallpaper() {
  WALLPAPER_DIR="$1"

  # Check if directory is valid

  if [ ! -d "$WALLPAPER_DIR" ]; then
    log_message "ERROR" "'$WALLPAPER_DIR' is not a directory."
    exit 1
  fi

  log_message "INFO" "Attempting to set new wallpaper from directory: $WALLPAPER_DIR"

  #  Check to see what the current wallpaper is

  CURRENT_WALLPAPER_URI=$(get_current_wallpaper)
  CURRENT_WALLPAPER_PATH=""
  if [[ "$CURRENT_WALLPAPER_URI" == file://* ]]; then
    CURRENT_WALLPAPER_PATH="${CURRENT_WALLPAPER_URI#file://}"
    log_message "INFO" "Current wallpaper path: $CURRENT_WALLPAPER_PATH"
  else
    log_message "WARN" "Could not determine current wallpaper path accurately."
  fi

  # Find the list of images in the given directory

  ALL_IMAGES=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))

  if [ -z "$ALL_IMAGES" ]; then
    log_message "ERROR" "No image files (jpg, jpeg, png) found in '$WALLPAPER_DIR'."
    exit 1
  fi

  # Cut our current wallpaper out of the acceptable set
  # - This is to prevent cases where we pick the same wallpaper twice in a row

  AVAILABLE_IMAGES=""
  if [ -n "$CURRENT_WALLPAPER_PATH" ]; then
    AVAILABLE_IMAGES=$(echo "$ALL_IMAGES" | grep -v "^${CURRENT_WALLPAPER_PATH}$")
  else
    AVAILABLE_IMAGES="$ALL_IMAGES"
  fi

  if [ -z "$AVAILABLE_IMAGES" ]; then
    if [ -n "$ALL_IMAGES" ]; then
        log_message "WARN" "Current wallpaper is the only one available or no other distinct images found. Will pick from all images."
        AVAILABLE_IMAGES="$ALL_IMAGES"
    else
        log_message "ERROR" "No images available to set after filtering and fallback."
        exit 1
    fi
  fi

  IMAGE_PATH=$(echo "$AVAILABLE_IMAGES" | shuf -n 1)

  if [ -z "$IMAGE_PATH" ]; then
    log_message "WARN" "No suitable image file found after initial selection. Attempting to pick any image from the directory..."
    if [ -n "$ALL_IMAGES" ]; then
        IMAGE_PATH=$(echo "$ALL_IMAGES" | shuf -n 1)
    fi
    if [ -z "$IMAGE_PATH" ]; then
        log_message "ERROR" "Failed to select any image from '$WALLPAPER_DIR'."
        exit 1
    fi
  fi

  log_message "INFO" "Selected image for new wallpaper: $IMAGE_PATH"

  # Actually set the wallpaper

  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'string:
var Desktops = desktops();
for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = Array("Wallpaper",
                                   "org.kde.image",
                                   "General");
        d.writeConfig("Image", "file://'"$IMAGE_PATH"'");
}'
  log_message "SUCCESS" "Wallpaper change command sent for: $IMAGE_PATH"
}

# Main script logic
if [ "$1" == "--get" ]; then
  CURRENT_WALLPAPER=$(get_current_wallpaper)
  if [ -n "$CURRENT_WALLPAPER" ]; then
    log_message "INFO" "Current wallpaper: $CURRENT_WALLPAPER"
  else
    log_message "WARN" "Could not determine current wallpaper."
  fi
elif [ -n "$1" ]; then
  set_new_wallpaper "$1"
else
  log_message "ERROR" "No directory path provided."
  printf "Usage:\n"
  printf "  %s <directory_path>    # Set a new random wallpaper from the directory (excluding current if possible)\n" "$0"
  printf "  %s --get                 # Get the current wallpaper path\n" "$0"
  exit 1
fi
