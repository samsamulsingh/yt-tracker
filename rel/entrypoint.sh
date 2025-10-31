#!/usr/bin/env sh
set -e

echo "Waiting for database to be available..."

# Simple wait loop for DATABASE_URL host availability (optional).
# If DATABASE_URL is not set, the release will fail with a helpful error.
if [ -z "${DATABASE_URL}" ]; then
  echo "DATABASE_URL is not set. Exiting." >&2
  exit 1
fi

# Optionally, you could parse host/port from DATABASE_URL and wait for it.
echo "Running database migrations..."
./bin/yt_tracker eval "YtTracker.ReleaseTasks.migrate()"

echo "Starting release..."
exec ./bin/yt_tracker start
