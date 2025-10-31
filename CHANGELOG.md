# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-30

### Added
- Initial release of YT Tracker
- Multi-tenant YouTube channel tracking system
- Full backfill support via YouTube Data API v3
- RSS feed polling with ETag/Last-Modified caching
- RESTful API with Bearer token authentication
- Rate limiting per API key
- Idempotency support for mutating requests
- Webhook system with HMAC-SHA256 signing
- Automatic retry logic for webhook deliveries
- Oban background job processing
- Channel registration and video enrichment
- Comprehensive API documentation
- PostgreSQL database with migrations
- Docker support
- Example curl commands and webhook verification code

### Features
- `/v1/channels` - Channel management endpoints
- `/v1/videos` - Video refresh and query endpoints
- `/v1/api_keys` - API key management
- `/v1/webhooks/endpoints` - Webhook endpoint management
- `/v1/webhooks/deliveries` - Webhook delivery tracking
- `/v1/status` - Health check endpoint

### Technical
- Phoenix 1.7.14
- Elixir 1.16+
- PostgreSQL
- Oban job queue
- Finch/Req HTTP client
- Bandit HTTP server
- Full test coverage with ExUnit
