# Monitoring & LiveView Features

## Overview

The YT Tracker project now includes:

1. **Phoenix LiveView Dashboard** - Real-time web interface for monitoring channels
2. **Automated Channel Monitoring** - Background job system that autonomously tracks YouTube channels
3. **Video Collections** - Organize videos with smart auto-add filters
4. **Web Scraping Fallback** - When API quota is exhausted, falls back to RSS/HTML scraping

## LiveView Dashboard

Access the dashboard at `http://localhost:4000/`

### Features:

- **Real-time Updates**: Dashboard automatically updates when new videos are detected
- **Channel Overview**: See all tracked channels with monitoring status
- **Enable/Disable Monitoring**: One-click monitoring control per channel
- **Recent Videos**: View the latest videos from all monitored channels
- **Collections**: Organize videos into smart collections with filters

## Automated Monitoring

### How It Works:

1. **Channel Monitors** - Each channel can have automated monitoring enabled
2. **Configurable Frequency** - Set check frequency per channel (default: 15 minutes)
3. **Background Worker** - Runs every 5 minutes to check channels that are due
4. **Auto-Collections** - Videos automatically added to collections based on filters

### Enable Monitoring via API:

```bash
# Enable monitoring with default settings
curl -X POST http://localhost:4000/v1/monitoring/enable \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "X-Tenant-Id: tenant1" \
  -H "Content-Type: application/json" \
  -d '{
    "channel_id": "CHANNEL_UUID",
    "frequency_minutes": 15
  }'
```

### Enable Monitoring via LiveView:

1. Navigate to the dashboard
2. Find the channel you want to monitor
3. Click the "Enable" button
4. The system will automatically check for new videos at the configured frequency

## Video Collections

Collections allow you to organize videos based on filters:

### Filter Types:

- **min_views**: Minimum view count
- **max_views**: Maximum view count
- **is_live**: Whether the video is live/upcoming
- **keyword**: Text search in title

### Example Collection with Auto-Add:

```elixir
# Create a collection for popular videos
YtTracker.Collections.create_collection(%{
  tenant_id: "tenant1",
  name: "Popular Videos",
  description: "Videos with over 100k views",
  auto_add_enabled: true,
  filters: %{
    "min_views" => 100_000
  }
})
```

## Web Scraping Fallback

When YouTube API quota is exhausted, the system automatically falls back to:

1. **RSS Feeds** - Parse YouTube's RSS feeds for recent videos
2. **HTML Scraping** - Extract data from channel/video pages using Floki

### Scraper Functions:

```elixir
# Scrape recent videos from RSS
{:ok, videos} = YtTracker.Scraper.scrape_channel_rss("UC_channel_id")

# Scrape channel info from page
{:ok, channel_info} = YtTracker.Scraper.scrape_channel_info("UC_channel_id")

# Scrape video stats
{:ok, stats} = YtTracker.Scraper.scrape_video_stats("video_id")
```

## Background Jobs

The system runs several background jobs:

### 1. PollRss Worker
- **Frequency**: Every 15 minutes
- **Purpose**: Polls RSS feeds for all channels to detect new videos
- **Queue**: `rss`

### 2. MonitorChannels Worker
- **Frequency**: Every 5 minutes
- **Purpose**: Checks which channel monitors are due and triggers polls
- **Queue**: `monitoring`

### 3. BackfillChannel Worker
- **Trigger**: On-demand via API
- **Purpose**: Fetches complete video history from YouTube API
- **Queue**: `backfill`

### 4. EnrichVideos Worker
- **Trigger**: After video creation
- **Purpose**: Fetches detailed statistics and metadata
- **Queue**: `enrich`

## Configuration

### Environment Variables:

```bash
# YouTube API (optional, falls back to scraping)
YOUTUBE_API_KEY=your_api_key_here

# Database
DATABASE_URL=postgresql://user:pass@localhost/yt_tracker_dev

# Monitoring defaults
DEFAULT_CHECK_FREQUENCY=15  # minutes
```

### Oban Configuration:

Located in `config/dev.exs` and `config/runtime.exs`:

```elixir
config :yt_tracker, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/15 * * * *", YtTracker.Workers.PollRss},
       {"*/5 * * * *", YtTracker.Workers.MonitorChannels}
     ]}
  ],
  queues: [
    default: 10,
    backfill: 5,
    enrich: 10,
    rss: 5,
    webhooks: 20,
    monitoring: 10
  ]
```

## Database Schema

### New Tables:

#### collections
- Organize videos into groups
- Support auto-add based on filters

#### collection_videos
- Junction table linking collections to videos
- Tracks who/when video was added

#### channel_monitors
- Configuration for automated channel monitoring
- Per-channel frequency settings
- Next check scheduling

#### video_cache
- Tracks which videos have been processed
- Prevents re-processing of existing videos

## Development Setup

### 1. Install Dependencies:

```bash
mix deps.get
cd assets && npm install
```

### 2. Setup Database:

```bash
mix ecto.create
mix ecto.migrate
```

### 3. Run Seeds (Optional):

```bash
./scripts/create_default_user.sh
```

### 4. Start Server:

```bash
mix phx.server
```

Access the LiveView dashboard at `http://localhost:4000`

## Production Deployment

### Asset Compilation:

```bash
mix assets.deploy
```

This will:
1. Install and run Tailwind CSS
2. Install and run ESBuild
3. Compile all assets to `priv/static/assets/`

### Docker Deployment:

The `docker-compose.yml` includes all necessary services:

```bash
docker-compose up -d
```

## API Endpoints

All existing API endpoints remain available at `/v1/*`:

- Channels: `/v1/channels`
- Videos: `/v1/videos`
- Webhooks: `/v1/webhooks/*`
- API Keys: `/v1/api_keys`

## Testing

Run tests:

```bash
mix test
```

Test specific modules:

```bash
mix test test/yt_tracker/monitoring_test.exs
mix test test/yt_tracker/collections_test.exs
```

## Monitoring Best Practices

1. **Set Appropriate Frequencies**: Don't check too often to avoid API quota issues
2. **Use Collections Wisely**: Filter collections to avoid duplicate processing
3. **Monitor API Usage**: Watch your YouTube API quota in Google Cloud Console
4. **Enable Scraping**: Ensure scraping works as backup when API quota runs out
5. **Review Logs**: Check Oban dashboard and logs for failed jobs

## Troubleshooting

### LiveView Not Loading:

1. Check assets are compiled: `mix assets.setup && mix assets.build`
2. Verify watchers are running in development
3. Check browser console for errors

### Monitoring Not Working:

1. Verify Oban is running: Check logs for cron job execution
2. Ensure channel monitors are enabled in dashboard
3. Check `next_check_at` is in the past for due monitors

### Scraping Issues:

1. YouTube may change HTML structure - update parsers as needed
2. Rate limiting - scraping too fast may trigger blocks
3. Use RSS feeds when possible (more stable than HTML scraping)

## License

See main project README for licensing information.
