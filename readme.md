💧 Dockerized Hydration Reminder App

This repository contains a simple, time-based water reminder application designed to run as a Docker container. It sends desktop notifications to your Linux host system at regular intervals, prompting you to stay hydrated!
🚀 How it Works

    Bash Script (water_reminder.sh): This script runs inside the Docker container. It acts as a timer, waiting for a configured interval (defaulting to 1 hour) before attempting to send a desktop notification.

    Docker Containerization: The application is packaged into a lightweight Alpine Linux Docker image. This ensures a consistent environment and easy deployment.

    Desktop Notifications: The container uses notify-send to communicate with your host's X server and display the reminders as native desktop notifications.

Important Note: Due to the isolated nature of Docker containers, this solution provides time-based reminders only. It cannot directly track your mouse or keyboard activity on the host system to trigger notifications.
🛠️ Requirements

    Docker and Docker Compose: Installed on your Linux system.

    Linux Host with X Server: This solution is designed for Linux distributions using the X Window System (most desktop Linuxes).

    Notification Daemon: Your host system needs a notification daemon running (e.g., dunst, xfce4-notifyd, GNOME's notification daemon) to display the notifications sent from the container.

⚠️ Security Considerations

For the Docker container to send desktop notifications to your host, it requires access to your host's X server. This is achieved by:

    Passing the DISPLAY environment variable.

    Mounting the /tmp/.X11-unix socket volume.

Running xhost +local: (or similar commands) on your host to grant this access reduces your system's security. Any local process (including other containers or malicious software) could potentially interact with your X server. Use this solution with caution and understand the risks, especially on multi-user systems or untrusted networks.
🚀 Getting Started

Follow these steps to set up and run the water reminder:
1. Save the Files

Ensure you have the following three files in the same directory:

    water_reminder.sh

    Dockerfile

    docker-compose.yml

<details><summary>Click to expand: water_reminder.sh content</summary>

#!/bin/bash

# Configuration for the reminder
NOTIFICATION_INTERVAL_SECONDS=$((60 * 60)) # 1 hour in seconds
NOTIFICATION_TITLE="💧 Hydration Reminder!"
NOTIFICATION_MESSAGE="You've been active for a while. Remember to drink some water!"
# Removed explicit icon to avoid 'icon not found' warnings. Notifications will be sent without a specific icon.

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
        # Removed the -i "$ICON" part to avoid icon not found warnings
        notify-send "$NOTIFICATION_TITLE" "$NOTIFICATION_MESSAGE"
        echo "Notification sent at $(date +"%H:%M:%S")"
    else
        echo "ERROR: Could not send notification at $(date +"%H:%M:%S")."
        echo "Possible reasons: 'notify-send' not found in container, or DISPLAY variable not set/accessible (X server connection issue)."
        echo "Please ensure libnotify, bash, dbus, dbus-x11, dunst, and font packages are installed in the container and DISPLAY is correctly mounted from your host."
    fi
done

</details>

<details><summary>Click to expand: Dockerfile content</summary>

# Use Alpine Linux as the base image for a lightweight footprint.
FROM alpine:latest

# Install necessary packages:
# - libnotify: Provides 'notify-send' for sending notifications.
# - bash: Needed to run the shell script correctly (due to #!/bin/bash).
# - dbus: Provides 'dbus-uuidgen' for machine-id.
# - dbus-x11: Provides 'dbus-launch' for D-Bus session management related to X.
# - dunst: The lightweight notification daemon that displays the pop-ups.
# - adwaita-icon-theme, hicolor-icon-theme: Provides standard system icons (though we're currently not using them).
# - ttf-dejavu: A common, general-purpose TrueType font package for Alpine. CRUCIAL for text rendering.
# - fontconfig: Library for configuring and customizing font access, and provides 'fc-cache'.
# apk update: Updates the list of available packages.
# apk add --no-cache: Installs the specified packages and removes the package cache
#                     after installation to further reduce image size.
RUN apk update && \
    apk add --no-cache libnotify bash dbus dbus-x11 dunst adwaita-icon-theme hicolor-icon-theme ttf-dejavu fontconfig && \
    rm -rf /var/cache/apk/*

# --- Fix for 'Cannot spawn a message bus without a machine-id' ---
# Create the /etc/machine-id file if it doesn't exist.
# D-Bus requires this file for proper functioning.
# We'll generate a UUID and put it into this file.
RUN mkdir -p /etc && \
    dbus-uuidgen > /etc/machine-id
# --- End of fix ---

# --- Fix for blank notifications (font rendering) ---
# Rebuild the font cache so dunst can find the newly installed fonts.
RUN fc-cache -fv
# --- End of fix ---

# Set the working directory inside the container.
WORKDIR /app

# Copy the water_reminder.sh script from your host machine into the /app directory.
# Ensure water_reminder.sh is in the same directory as your Dockerfile.
COPY water_reminder.sh .

# Make the script executable.
RUN chmod +x water_reminder.sh

# Define the command that will be executed when the container starts.
# We'll start 'dunst' (the notification daemon) in the background,
# then execute your water reminder script.
# This ensures that a service is available on D-Bus to handle notifications.
CMD dunst & ./water_reminder.sh

</details>

<details><summary>Click to expand: docker-compose.yml content</summary>

# Specify the Docker Compose file format version.
version: '3.8'

# Define the services (containers) that make up your application.
services:
  water-reminder:
    # Build the image from the Dockerfile in the current directory.
    build: .
    
    # Assign a custom name to the container for easy identification.
    container_name: water-reminder-app

    # Environment variables to pass into the container.
    # The DISPLAY variable is essential for X applications (like notify-send)
    # to know which display server on the host to connect to.
    # WARNING: Exposing DISPLAY like this has security implications!
    # Only use if you understand the risks and are on a trusted network.
    environment:
      - DISPLAY=${DISPLAY} # ${DISPLAY} will automatically pick up your host's DISPLAY variable.

    # Volume mounts connect directories/files from your host to the container.
    # This is critical for the container to interact with your host's X server.
    volumes:
      # Mount the X server's Unix socket directory. This allows the container
      # to communicate with the host's graphical display server.
      - /tmp/.X11-unix:/tmp/.X11-unix
      # Mount the script directly from the host.
      # This allows you to edit `water_reminder.sh` on your host and have
      # the changes reflected in the container without rebuilding the image.
      # If you modify the script, you might need to restart the container:
      # `docker compose restart water-reminder`
      - ./water_reminder.sh:/app/water_reminder.sh

    # Restart policy for the container.
    # 'unless-stopped': Always restart the container unless it is explicitly stopped (e.g., via `docker compose stop`).
    restart: unless-stopped

</details>
2. Set Script Permissions (Host Machine)

Ensure the water_reminder.sh script on your host machine has execute permissions:

chmod +x water_reminder.sh

3. Allow X Server Access (Linux Host Only - If Needed)

If notifications don't appear, you might need to temporarily allow local connections to your X server. Open a new terminal window on your host machine and run:

xhost +local:

    Remember the security implications! This command reduces security. For a more secure approach, research xauth or more granular xhost commands like xhost +si:localuser:$(whoami).

    To revoke this permission later, run xhost -local: in your host terminal.

4. Build and Run the Container

Navigate to the directory containing your three files in your terminal and execute:

docker compose up --build -d

    docker compose up: Starts the services defined in docker-compose.yml.

    --build: Builds the Docker image first (if it doesn't exist or if changes are made to the Dockerfile).

    -d: Runs the container in detached mode (in the background).

5. Verify and Enjoy!

After running the command, you should see logs indicating the container starting. After the specified NOTIFICATION_INTERVAL_SECONDS (1 hour by default), you should receive a desktop notification.

🛑 Stopping the Reminder

To stop the water reminder container, navigate to the same directory in your terminal and run:

docker compose down
