#!/bin/bash

# Configuration for the reminder
# Read interval from environment variable, default to 3600 seconds (1 hour)
NOTIFICATION_INTERVAL_SECONDS="${REMINDER_DURATION_SECONDS:-3600}"

NOTIFICATION_TITLE="💧 Hydration Reminder!"
NOTIFICATION_MESSAGE="You've been active for a while. Remember to drink some water!"

# Active hours and days configuration
ACTIVE_HOURS_START="${ACTIVE_HOURS_START:-9}"     # 9 AM
ACTIVE_HOURS_END="${ACTIVE_HOURS_END:-18}"       # 6 PM
ACTIVE_DAYS="${ACTIVE_DAYS:-"1-5"}"              # Monday-Friday (1=Mon,7=Sun)
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"  

# ICON is now handled by the emoji in NOTIFICATION_TITLE, no need to pass -i to notify-send
# If you prefer a themed icon, you can uncomment ICON and add -i "$ICON" back to notify-send,
# but ensure the icon name is resolvable by dunst and its configured icon_theme.
# ICON="dialog-information"

echo "Starting water reminder. You will be reminded every $((NOTIFICATION_INTERVAL_SECONDS / 60)) minutes."
echo "---------------------------------------------------------"
echo "NOTE: This script provides TIME-BASED reminders only."
echo "Direct mouse/keyboard tracking from inside Docker to your host GUI is complex and not implemented here."
echo "For notifications to appear on your desktop (Linux host):"
echo "  1. Ensure 'notify-send' is working on your host system."
echo "  2. You might need to allow local connections to your X server."
echo "     (e.g., by running 'xhost +local:' in your host terminal BEFORE starting Docker Compose)."
echo "     Be aware of the security implications of 'xhost +local:'."
echo "---------------------------------------------------------"

is_active_time() {
    current_hour=$(date +%H)
    current_day=$(date +%u)  # 1-7 (Mon-Sun)
    
    # Check if current day is in active days
    if [[ "$ACTIVE_DAYS" == *"-"* ]]; then
        # Handle range like "1-7"
        start_day=${ACTIVE_DAYS%-*}
        end_day=${ACTIVE_DAYS#*-}
        if [[ $current_day < $start_day || $current_day > $end_day ]]; then
            return 1
        fi
    fi
    
    # Check if current hour is in active window
    if [ "$current_hour" -lt "$ACTIVE_HOURS_START" ] || [ "$current_hour" -ge "$ACTIVE_HOURS_END" ]; then
        return 1
    fi
    
    return 0
}

# Loop indefinitely to send reminders
while true; do

    if is_active_time; then
        echo "Active time detected at $(date +"%H:%M:%S")."
    else
        echo "Inactive time detected at $(date +"%H:%M:%S"). Skipping notification."
        sleep "$NOTIFICATION_INTERVAL_SECONDS"
        continue
    fi
    # Simplified echo statement, compatible with Alpine's 'date'
    echo "Waiting for $NOTIFICATION_INTERVAL_SECONDS seconds... (Current time: $(date +"%H:%M:%S"))"
    sleep "$NOTIFICATION_INTERVAL_SECONDS" # Use quotes around variable for safety

    # Attempt to send a notification
    # Check if notify-send is available and DISPLAY environment variable is set
    if command -v notify-send &> /dev/null && [ -n "$DISPLAY" ]; then
        # Sending notification without an explicit icon file/name.
        # The emoji in NOTIFICATION_TITLE will serve as the visual cue.
        notify-send "$NOTIFICATION_TITLE" "$NOTIFICATION_MESSAGE"
        echo "Notification sent at $(date +"%H:%M:%S")"
    else
        echo "ERROR: Could not send notification at $(date +"%H:%M:%S")."
        echo "Possible reasons: 'notify-send' not found in container, or DISPLAY variable not set/accessible (X server connection issue)."
        echo "Please ensure libnotify, bash, dbus, dbus-x11, dunst, and font packages are installed in the container and DISPLAY is correctly mounted from your host."
    fi
done
