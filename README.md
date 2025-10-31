# YT Tracker

A production-grade Phoenix 1.7 application for tracking YouTube channels and videos with a comprehensive REST API.

## Features

- 🎥 **Full YouTube Channel Backfill** - Complete historical video data via YouTube Data API v3
- 📡 **RSS Feed Polling** - Efficient tracking of new uploads with ETag/Last-Modified caching
- 🏢 **Multi-Tenant Architecture** - Isolated data per tenant via `X-Tenant-Id` header
- ⚙️ **Background Jobs** - Oban-powered workers for backfill, enrichment, and polling
- 🔐 **Secure API** - Bearer token authentication, rate limiting, and idempotency
- 🪝 **Webhooks** - Event notifications with HMAC-SHA256 signing and automatic retries
- 📊 **PostgreSQL** - Fully migrated Ecto schema
- 🚀 **Production Ready** - Comprehensive error handling, logging, and monitoring

## Tech Stack

- **Elixir** ≥ 1.16
- **Phoenix** 1.7.14
- **Ecto** + PostgreSQL
- **Oban** - Background job processing
- **Finch/Req** - HTTP client
- **Bandit** - HTTP server
- **SweetXml** - XML parsing for RSS

## Quick Start

### Prerequisites

- Elixir 1.16+ and Erlang 26+
- PostgreSQL 14+
- YouTube Data API v3 key ([Get one here](https://console.developers.google.com/))

### Installation

1. **Clone and setup:**

```bash
cd /path/to/project
mix deps.get
```

2. **Configure environment:**

```bash
cp .env.example .env
# Edit .env and set your YOUTUBE_API_KEY and other vars
```

3. **Create and migrate database:**

```bash
mix ecto.setup
```

This will:
- Create the database
- Run migrations
- Seed a default "public" tenant
- Generate a development API key (save this!)

4. **Start the server:**

```bash
mix phx.server
```

The API will be available at `http://localhost:4000/v1`

## Environment Variables

```bash
DATABASE_URL=ecto://postgres:postgres@localhost/yt_tracker_dev
YOUTUBE_API_KEY=your_youtube_api_key_here
ALLOW_ORIGINS=http://localhost:3000,https://app.example.com
PORT=4000
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret

# Feature flags
WEBSUB_ENABLED=false
PUBLIC_API_ENABLED=true

# Rate limiting
RATE_LIMIT=100
RATE_LIMIT_WINDOW=60
```

## API Documentation

### Authentication

All API requests require a Bearer token:

```bash
Authorization: Bearer yttr_YOUR_API_KEY_HERE
```

### Multi-Tenancy

Specify tenant via header (defaults to "public"):

```bash
X-Tenant-Id: your-tenant-slug
```

### Endpoints

#### Status

```bash
GET /v1/status
```

Returns API health and version info.

#### Channels

**Register a channel:**

```bash
POST /v1/channels
Content-Type: application/json

{
  "youtube_id": "UCxxx..."
}
```

This will:
1. Fetch channel metadata from YouTube API
2. Store channel details
3. Schedule a backfill job for all videos

**List channels:**

```bash
GET /v1/channels
```

**Get channel details:**

```bash
GET /v1/channels/:id
```

**Trigger backfill:**

```bash
POST /v1/channels/:id/backfill
```

**Poll RSS feed:**

```bash
POST /v1/channels/:id/poll
```

**List channel videos:**

```bash
GET /v1/channels/:id/videos?since=2024-01-01T00:00:00Z&limit=50
```

Query parameters:
- `since` - ISO8601 datetime
- `until` - ISO8601 datetime
- `is_live` - true/false
- `search` - text search in title/description
- `limit` - max results

#### Videos

**Refresh video metadata:**

```bash
POST /v1/videos/refresh
Content-Type: application/json

{
  "video_ids": ["video_id_1", "video_id_2"]
}
```

Max 50 video IDs per request.

#### API Keys

**Create API key:**

```bash
POST /v1/api_keys
Content-Type: application/json

{
  "name": "My App Key",
  "rate_limit": 1000,
  "rate_window_seconds": 60,
  "scopes": ["*"]
}
```

Returns the full key **only once** - save it!

**List API keys:**

```bash
GET /v1/api_keys
```

**Delete API key:**

```bash
DELETE /v1/api_keys/:id
```

#### Webhooks

**Create webhook endpoint:**

```bash
POST /v1/webhooks/endpoints
Content-Type: application/json

{
  "url": "https://your-app.com/webhooks",
  "events": ["video.created", "video.updated"],
  "description": "My webhook"
}
```

Events:
- `video.created` - New video detected
- `video.updated` - Video metadata changed
- `*` - All events

**List webhook endpoints:**

```bash
GET /v1/webhooks/endpoints
```

**Delete webhook endpoint:**

```bash
DELETE /v1/webhooks/endpoints/:id
```

**List deliveries:**

```bash
GET /v1/webhooks/deliveries?endpoint_id=xxx
```

### Response Format

Success response:

```json
{
  "data": { ... },
  "meta": {
    "count": 10
  },
  "links": {
    "next": "cursor_token"
  }
}
```

Error response (RFC 7807):

```json
{
  "error": {
    "type": "validation_error",
    "title": "Validation Error",
    "detail": "Invalid input parameters",
    "status": 422
  }
}
```

### Rate Limiting

Default: 100 requests per 60 seconds per API key.

When rate limited, you'll receive:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 45

{
  "error": {
    "type": "rate_limit_exceeded",
    "title": "Rate Limit Exceeded",
    "detail": "Too many requests. Please try again in 45 seconds."
  }
}
```

### Idempotency

For POST/PUT/PATCH/DELETE requests, include:

```bash
Idempotency-Key: unique-key-for-this-request
```

The first request with this key will be processed normally. Subsequent requests with the same key will return the cached response.

## Webhooks Integration

### Receiving Webhooks

Your webhook endpoint will receive POST requests with:

**Headers:**
```
Content-Type: application/json
X-Webhook-Signature: sha256=<hmac_signature>
X-Webhook-Event: video.created
X-Webhook-Id: <delivery_id>
```

**Body:**
```json
{
  "video_id": "uuid",
  "youtube_id": "abc123",
  "title": "Video Title",
  "published_at": "2024-01-01T00:00:00Z"
}
```

### Verifying Signatures

**Python example:**

```python
import hmac
import hashlib

def verify_webhook(payload_body, signature_header, secret):
    """Verify webhook signature"""
    expected_sig = hmac.new(
        secret.encode('utf-8'),
        payload_body,
        hashlib.sha256
    ).hexdigest()
    
    # Extract signature from header (format: "sha256=<hex>")
    provided_sig = signature_header.replace('sha256=', '')
    
    return hmac.compare_digest(expected_sig, provided_sig)

# Usage
secret = "your_webhook_secret"
is_valid = verify_webhook(
    request.body,
    request.headers.get('X-Webhook-Signature'),
    secret
)
```

**Node.js example:**

```javascript
const crypto = require('crypto');

function verifyWebhook(payloadBody, signatureHeader, secret) {
  const expectedSig = crypto
    .createHmac('sha256', secret)
    .update(payloadBody)
    .digest('hex');
  
  const providedSig = signatureHeader.replace('sha256=', '');
  
  return crypto.timingSafeEqual(
    Buffer.from(expectedSig),
    Buffer.from(providedSig)
  );
}
```

### Retry Logic

Failed webhook deliveries are retried with exponential backoff:

1. 1 minute
2. 5 minutes
3. 15 minutes
4. 1 hour
5. 24 hours

After 5 attempts, the delivery is marked as failed.

## Background Jobs

### Oban Workers

- **BackfillChannel** - Fetches all videos from a channel's uploads playlist
- **EnrichVideos** - Fetches full metadata for videos (views, likes, duration, etc.)
- **PollRss** - Checks RSS feeds for new videos (runs every 15 minutes via cron)
- **WebhookDelivery** - Delivers webhook events with retries

### Monitoring Jobs

Access Oban dashboard in development:

```
http://localhost:4000/dev/dashboard
```

## Database Schema

### Tenants
- Multi-tenant isolation
- Each tenant has isolated channels, videos, API keys, webhooks

### YouTube Channels
- Channel metadata from YouTube API
- RSS polling state (ETag, Last-Modified)
- WebSub subscription info (optional)

### YouTube Videos
- Full video metadata and statistics
- Soft-delete support
- Live stream detection

### API Keys
- Tenant-scoped authentication
- Per-key rate limits
- Scopes and expiration

### Webhook Endpoints
- Event subscriptions
- HMAC secrets for signing

### Webhook Deliveries
- Delivery attempts and status
- Response tracking
- Retry scheduling

### Idempotency Keys
- Request deduplication
- Cached responses

## Development

### Run tests

```bash
mix test
```

### Database migrations

```bash
# Create migration
mix ecto.gen.migration migration_name

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback
```

### Format code

```bash
mix format
```

### Static analysis

```bash
mix credo
```

## Production Deployment

### Environment Setup

1. Set all required environment variables
2. Generate a secure `SECRET_KEY_BASE`:

```bash
mix phx.gen.secret
```

3. Set `DATABASE_URL` to your PostgreSQL instance
4. Configure `PHX_HOST` and `PORT`

### Database

```bash
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

### Running

```bash
MIX_ENV=prod mix release
_build/prod/rel/yt_tracker/bin/yt_tracker start
```

Or with Docker:

```dockerfile
FROM elixir:1.16-alpine AS build

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

FROM alpine:3.18
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app
COPY --from=build /app/_build/prod/rel/yt_tracker ./

CMD ["bin/yt_tracker", "start"]
```

## Example Usage

### cURL Examples

**Register a channel:**

```bash
curl -X POST http://localhost:4000/v1/channels \
  -H "Authorization: Bearer yttr_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"youtube_id": "UCxxx..."}'
```

**List videos:**

```bash
curl http://localhost:4000/v1/channels/{channel_id}/videos?limit=10 \
  -H "Authorization: Bearer yttr_YOUR_KEY"
```

**Create webhook:**

```bash
curl -X POST http://localhost:4000/v1/webhooks/endpoints \
  -H "Authorization: Bearer yttr_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks",
    "events": ["video.created"]
  }'
```

## Architecture

```
┌─────────────┐
│   Phoenix   │
│  Endpoint   │
└──────┬──────┘
       │
       ├─ ApiAuthPlug (Bearer token)
       ├─ RateLimitPlug (Per-key limits)
       ├─ IdempotencyPlug (Request dedup)
       └─ CORSPlug
       │
┌──────┴──────────────────────────┐
│         Controllers              │
│  Channel │ Video │ Webhook │... │
└──────┬──────────────────────────┘
       │
┌──────┴──────────────────────────┐
│          Contexts                │
│  Channels │ Videos │ Webhooks   │
└──────┬──────────────────────────┘
       │
┌──────┴──────────────────────────┐
│      External Services           │
│  YouTubeApi │ RSS │ Oban         │
└─────────────────────────────────┘
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Write tests
4. Ensure `mix test` and `mix credo` pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: [your-repo/issues]
- Email: support@example.com

---

Built with ❤️ using Elixir and Phoenix
