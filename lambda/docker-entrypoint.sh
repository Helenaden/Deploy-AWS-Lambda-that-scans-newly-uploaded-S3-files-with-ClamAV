#!/bin/sh

# Update virus definitions
freshclam -d &

# Start the ClamAV daemon in the background
clamd &

# Wait for the daemon to be ready
while ! clamdscan --ping 2>/dev/null; do
  echo "Waiting for clamd to start..."
  sleep 2
done
echo "clamd is running!"

# Execute the main Lambda function handler
exec "$@"
