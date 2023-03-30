#!/bin/bash

# Prompt the user for the URLs of the RTSP streams
read -p "Enter the URL for the first RTSP stream: " stream1
read -p "Enter the URL for the second RTSP stream: " stream2

# Prompt the user for the sleep time between stream switches
read -p "Enter the time to sleep between switches (in seconds): " sleep_time

# Create the stream switcher script
cat <<EOF >stream-switcher.sh
#!/bin/bash

# Define the RTSP streams
stream1="$stream1"
stream2="$stream2"

# Define the screen session name
session="stream-switcher"

# Start the screen session
screen -dmS \$session

# Infinite loop to switch between the streams
while true; do
  # Play the first stream in the screen session
  screen -S \$session -X stuff "mpv \$stream1$(printf \\r)"

  # Sleep for the specified time to allow the first stream to play
  sleep $sleep_time

  # Stop the first stream
  screen -S \$session -X stuff "q$(printf \\r)"

  # Play the second stream in the screen session
  screen -S \$session -X stuff "mpv \$stream2$(printf \\r)"

  # Sleep for the specified time to allow the second stream to play
  sleep $sleep_time

  # Stop the second stream
  screen -S \$session -X stuff "q$(printf \\r)"
done
EOF

# Make the stream switcher script executable
chmod +x stream-switcher.sh

# Create the systemd service file
cat <<EOF >/etc/systemd/system/stream-switcher.service
[Unit]
Description=Stream Switcher
After=network.target

[Service]
ExecStart=/bin/bash $(pwd)/stream-switcher.sh
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new service
systemctl daemon-reload

# Start the stream switcher service and enable it to start on boot
systemctl start stream-switcher.service
systemctl enable stream-switcher.service

echo "Stream switcher setup complete!"
