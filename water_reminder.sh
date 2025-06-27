#!/bin/bash

# Configuration for the reminder
NOTIFICATION_INTERVAL_SECONDS=$((30 * 1)) # 1 hour in seconds
NOTIFICATION_TITLE="💧 Hydration Reminder!"
NOTIFICATION_MESSAGE="You've been active for a while. Remember to drink some water!"
# Changed icon to 'info' which is more universally available or often built-in to notification daemons.
# Other options could be empty string "" (no icon) or 'dialog-warning' (if semantic fits).
ICON="info" # A standard Freedesktop icon like 'info', or 'dialog-error', 'dialog-warning'.

echo "Starting water reminder. You will be reminded every hour."
echo "---------------------------------------------------------"
echo "NOTE: This script provides TIME-BASED reminders only."
echo "Direct mouse/keyboard tracking from inside Docker to your host GUI is complex and not implemented here."
echo "For notifications to appear on your desktop (Linux host):"
echo "  1. Ensure 'notify-send' is working on your host system."
echo "  2. You might need to allow local connections to your X server."
echo "     (e.g., by running 'xhost +local:' in your host terminal BEFORE starting Docker Compose)."
echo "     Be aware of the security implications of 'xhost +local:'."
echo "---------------------------------------------------------"

# Loop indefinitely to send reminders
while true; do
    # Simplified echo statement, compatible with Alpine's 'date'
    echo "Waiting for $NOTIFICATION_INTERVAL_SECONDS seconds... (Current time: $(date +"%H:%M:%S"))"
    sleep $NOTIFICATION_INTERVAL_SECONDS

    # Attempt to send a notification
    # Check if notify-send is available and DISPLAY environment variable is set
    if command -v notify-send &> /dev/null && [ -n "$DISPLAY" ]; then
        notify-send -i "$ICON" "$NOTIFICATION_TITLE" "$NOTIFICATION_MESSAGE"
        echo "Notification sent at $(date +"%H:%M:%S")"
    else
        echo "ERROR: Could not send notification at $(date +"%H:%M:%S")."
        echo "Possible reasons: 'notify-send' not found in container, or DISPLAY variable not set/accessible (X server connection issue)."
        echo "Please ensure libnotify, bash, dbus, dbus-x11, dunst, and icon themes are installed in the container and DISPLAY is correctly mounted from your host."
    fi
done

