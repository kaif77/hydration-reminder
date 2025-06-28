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
    apk add --no-cache libnotify bash dbus dbus-x11 dunst adwaita-icon-theme font-noto-emoji hicolor-icon-theme ttf-dejavu fontconfig tzdata && \
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

