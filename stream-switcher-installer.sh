#!/bin/bash

# Install dependencies
sudo apt-get update
sudo apt-get install -y mpv screen

# Get stream URLs and sleep time from user
read -p "Enter URL for stream 1: " stream1_url
read -p "Enter URL for stream 2: " stream2_url
read -p "Enter sleep time (in seconds) between switches: " sleep_time

# Create stream-switcher.conf file with user input
echo "STREAM1_URL=\"$stream1_url\"" | sudo tee /etc/stream-switcher.conf
echo "STREAM2_URL=\"$stream2_url\"" | sudo tee -a /etc/stream-switcher.conf
echo "SLEEP_TIME=$sleep_time" | sudo tee -a /etc/stream-switcher.conf

# Create stream-switcher.sh script
sudo tee /usr/local/bin/stream-switcher.sh > /dev/null <<EOF
#!/bin/bash

# Load configuration from stream-switcher.conf
source /etc/stream-switcher.conf

# Start an infinite loop
while true; do
  # Start playing the first stream
  mpv --no-video "$STREAM1_URL" &
  # Wait for the specified sleep time
  sleep "$SLEEP_TIME"
  # Stop playing the first stream
  pkill mpv
  # Start playing the second stream
  mpv --no-video "$STREAM2_URL" &
  # Wait for the specified sleep time
  sleep "$SLEEP_TIME"
  # Stop playing the second stream
  pkill mpv
done
EOF

# Make stream-switcher.sh executable
sudo chmod +x /usr/local/bin/stream-switcher.sh

# Create stream-switcher.service file
sudo tee /etc/systemd/system/stream-switcher.service > /dev/null <<EOF
[Unit]
Description=Stream Switcher
After=network.target

[Service]
ExecStart=/usr/local/bin/stream-switcher.sh
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl enable stream-switcher.service
sudo systemctl start stream-switcher.service

echo "Installation complete. The stream switcher service is now running and will start automatically on boot."

# Allow the user to re-run the installation queries
while true; do
  read -p "Do you want to change the stream URLs or sleep time? [y/n] " yn
  case $yn in
    [Yy]* ) sudo nano /etc/stream-switcher.conf; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done
