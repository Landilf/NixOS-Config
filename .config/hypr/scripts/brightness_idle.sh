#!/usr/bin/env bash

# File to store the brightness before dimming
BRIGHTNESS_FILE="/tmp/hypr_brightness_backup"

# Get current brightness
get_brightness() {
    brightnessctl get
}

# Set brightness
set_brightness() {
    brightnessctl set "$1"
}

case "$1" in
    dim)
        # Only save if we haven't already (to avoid overwriting with a dimmed value)
        if [ ! -f "$BRIGHTNESS_FILE" ]; then
            get_brightness > "$BRIGHTNESS_FILE"
            # Set to minimum (e.g., 5% or 10, depending on preference)
            # Using 5% to ensure it's not completely off but very dim
            brightnessctl set 5%
        fi
        ;;
    restore)
        if [ -f "$BRIGHTNESS_FILE" ]; then
            SAVED_BRIGHTNESS=$(cat "$BRIGHTNESS_FILE")
            set_brightness "$SAVED_BRIGHTNESS"
            rm "$BRIGHTNESS_FILE"
        fi
        ;;
    *)
        echo "Usage: $0 {dim|restore}"
        exit 1
        ;;
esac
