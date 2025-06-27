#!/bin/bash

# Configuration for the reminder
# Read interval from environment variable, default to 3600 seconds (1 hour)
NOTIFICATION_INTERVAL_SECONDS="${REMINDER_DURATION_SECONDS:-3600}"

NOTIFICATION_TITLE="💧 Hydration Reminder!"
NOTIFICATION_MESSAGE="You've been active for a while. Remember to drink some water!"
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

# Loop indefinitely to send reminders
while true; do
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
