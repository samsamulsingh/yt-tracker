# Quick Start Guide - YT Tracker

## ⚡ Get Started in 5 Minutes

### Step 1: Prerequisites Check

```bash
# Check Elixir version (need 1.16+)
elixir --version

# Check PostgreSQL is running
pg_isready

# If not running, start PostgreSQL:
# macOS: brew services start postgresql
# Linux: sudo systemctl start postgresql
```

### Step 2: Setup Project

```bash
cd /Users/anshika/Desktop/working\ projects/yt_tracker

# Install dependencies
mix deps.get

# Copy environment template
cp .env.example .env
```

### Step 3: Configure API Key

Edit `.env` and add your YouTube API key:

```bash
YOUTUBE_API_KEY=AIza...your_key_here
```

Get a YouTube API key here: https://console.developers.google.com/

### Step 4: Initialize Database

```bash
mix ecto.setup
```

**Important:** Save the API key shown in the output! It looks like:
```
yttr_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Step 5: Start Server

```bash
mix phx.server
```

You should see:
```
[info] Running YtTrackerWeb.Endpoint with Bandit 1.5.x at 127.0.0.1:4000 (http)
```

### Step 6: Test It!

```bash
# Replace YOUR_API_KEY with the key from step 4
export API_KEY="yttr_YOUR_KEY_HERE"

# Test health endpoint
curl http://localhost:4000/v1/status \
  -H "Authorization: Bearer $API_KEY"

# Should return:
# {
#   "data": {
#     "status": "ok",
#     "version": "1.0.0",
#     "timestamp": "..."
#   }
# }
```

### Step 7: Register Your First Channel

```bash
# Register Fireship's channel
curl -X POST http://localhost:4000/v1/channels \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"youtube_id": "UCsBjURrPoezykLs9EqgamOA"}'
```

This will:
1. Fetch channel metadata from YouTube
2. Store the channel
3. Start backfilling all historical videos
4. Schedule RSS polling

### Step 8: Check Progress

```bash
# List all channels
curl http://localhost:4000/v1/channels \
  -H "Authorization: Bearer $API_KEY"

# Get videos (replace CHANNEL_ID with ID from previous response)
curl http://localhost:4000/v1/channels/CHANNEL_ID/videos?limit=10 \
  -H "Authorization: Bearer $API_KEY"
```

## 🎯 Common Tasks

### View Background Jobs

```bash
# Open browser to:
http://localhost:4000/dev/dashboard
```

Click "Oban" to see job queue status.

### Create More API Keys

```bash
curl -X POST http://localhost:4000/v1/api_keys \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "My App", "rate_limit": 500}'
```

### Set Up Webhooks

```bash
curl -X POST http://localhost:4000/v1/webhooks/endpoints \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks",
    "events": ["video.created"]
  }'
```

### Run Tests

```bash
mix test
```

### Format Code

```bash
mix format
```

## 🐛 Troubleshooting

### "YouTube API key not configured"
- Make sure you set `YOUTUBE_API_KEY` in `.env`
- Restart the server after editing `.env`

### "Connection refused" to database
- Check PostgreSQL is running: `pg_isready`
- Check connection details in `config/dev.exs`

### "Module not found" errors
- Run `mix deps.get` again
- Run `mix clean && mix compile`

### Can't find API key after setup
- Run `mix run priv/repo/seeds.exs` again
- Or create one manually via API

## 📖 Next Steps

- Read the full [README.md](README.md)
- Check out [examples/](examples/)
- Read API documentation in README
- Set up webhooks for your app
- Deploy to production (see README)

## 🎉 You're Ready!

The YT Tracker API is now running and ready to track YouTube channels!

For questions or issues, check the main README.md or open an issue.
