#!/bin/bash
set -e

echo "🚀 Starting YT Tracker setup..."

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "❌ Elixir is not installed. Please install Elixir 1.16+ first."
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready &> /dev/null; then
    echo "⚠️  PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get

# Create and migrate database
echo "🗄️  Setting up database..."
mix ecto.setup

echo "✅ Setup complete!"
echo ""
echo "📝 Your development API key has been generated (check the output above)"
echo ""
echo "To start the server:"
echo "  mix phx.server"
echo ""
echo "The API will be available at http://localhost:4000/v1"
