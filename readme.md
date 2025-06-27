# 💧 Dockerized Hydration Reminder

A simple Dockerized app that sends periodic desktop notifications on Linux, reminding you to drink water.

## How It Works

- Runs a Bash script inside a Docker container.
- Sends a desktop notification every hour (configurable).
- Uses `notify-send` to display reminders on your Linux desktop.

## Quick Start

1. **Clone or Download** this repository.

2. **Set Script Permissions** (on your host):
   ```
   chmod +x water_reminder.sh
   ```

3. **Allow X Server Access** (if needed, on your host):
   ```
   xhost +local:
   ```

4. **(Optional) Adjust Reminder Interval:**  
    ```
   You can change the reminder interval by editing the `REMINDER_DURATION_SECONDS` value in the `docker-compose.yml` file.  
   The default value is set to **30 seconds**.
    ```
5. **Build and Run** the container:
   ```
   docker compose up --build -d
   ```

6. **Stop** the reminder:
   ```
   docker compose down
   ```

> Make sure Docker and an X server are running on your Linux system.  
> Notifications require a notification daemon (like dunst, xfce4-notifyd, or GNOME's notification daemon).