#!/bin/bash
# Example deployment script for production

set -e

echo "🚀 Deploying YT Tracker..."

# Pull latest code
git pull origin main

# Install/update dependencies
echo "📦 Updating dependencies..."
mix deps.get --only prod
MIX_ENV=prod mix compile

# Run migrations
echo "🗄️  Running migrations..."
MIX_ENV=prod mix ecto.migrate

# Build release
echo "🔨 Building release..."
MIX_ENV=prod mix release --overwrite

echo "✅ Deployment complete!"
echo ""
echo "To start the server:"
echo "  _build/prod/rel/yt_tracker/bin/yt_tracker start"
