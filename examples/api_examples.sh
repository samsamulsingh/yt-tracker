#!/bin/bash
# Example curl commands for YT Tracker API

# Set your API key
API_KEY="yttr_YOUR_API_KEY_HERE"
BASE_URL="http://localhost:4000"

echo "🔍 YT Tracker API Examples"
echo "================================"
echo ""

# 1. Check API status
echo "1️⃣  Check API Status"
curl -s "$BASE_URL/v1/status" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 2. Register a YouTube channel
echo "2️⃣  Register a YouTube Channel"
curl -s -X POST "$BASE_URL/v1/channels" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"youtube_id": "UCsBjURrPoezykLs9EqgamOA"}' | jq .
echo ""

# 3. List all channels
echo "3️⃣  List All Channels"
curl -s "$BASE_URL/v1/channels" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 4. Get channel videos (replace CHANNEL_ID)
echo "4️⃣  Get Channel Videos"
CHANNEL_ID="YOUR_CHANNEL_ID"
curl -s "$BASE_URL/v1/channels/$CHANNEL_ID/videos?limit=5" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 5. Create a new API key
echo "5️⃣  Create New API Key"
curl -s -X POST "$BASE_URL/v1/api_keys" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "My New Key", "rate_limit": 500}' | jq .
echo ""

# 6. Create a webhook endpoint
echo "6️⃣  Create Webhook Endpoint"
curl -s -X POST "$BASE_URL/v1/webhooks/endpoints" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks",
    "events": ["video.created", "video.updated"],
    "description": "My webhook"
  }' | jq .
echo ""

# 7. Trigger channel backfill
echo "7️⃣  Trigger Channel Backfill"
curl -s -X POST "$BASE_URL/v1/channels/$CHANNEL_ID/backfill" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 8. Poll RSS feed
echo "8️⃣  Poll Channel RSS Feed"
curl -s -X POST "$BASE_URL/v1/channels/$CHANNEL_ID/poll" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 9. Refresh video metadata
echo "9️⃣  Refresh Video Metadata"
curl -s -X POST "$BASE_URL/v1/videos/refresh" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"video_ids": ["video_id_1", "video_id_2"]}' | jq .
echo ""

# 10. Search videos
echo "🔟 Search Channel Videos"
curl -s "$BASE_URL/v1/channels/$CHANNEL_ID/videos?search=tutorial&limit=10" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 11. Filter videos by date
echo "1️⃣1️⃣  Filter Videos by Date"
curl -s "$BASE_URL/v1/channels/$CHANNEL_ID/videos?since=2024-01-01T00:00:00Z&limit=10" \
  -H "Authorization: Bearer $API_KEY" | jq .
echo ""

# 12. Use idempotency key
echo "1️⃣2️⃣  Request with Idempotency Key"
curl -s -X POST "$BASE_URL/v1/channels" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Idempotency-Key: unique-key-123" \
  -H "Content-Type: application/json" \
  -d '{"youtube_id": "UCsBjURrPoezykLs9EqgamOA"}' | jq .
echo ""

echo "✅ Examples complete!"
