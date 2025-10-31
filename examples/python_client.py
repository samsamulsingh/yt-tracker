#!/usr/bin/env python3
"""
Example Python client for YT Tracker API
Demonstrates authentication, channel registration, and webhook verification
"""

import os
import hmac
import hashlib
import json
import requests
from datetime import datetime

class YtTrackerClient:
    def __init__(self, base_url, api_key, tenant_id="public"):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.tenant_id = tenant_id
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'X-Tenant-Id': tenant_id,
            'Content-Type': 'application/json'
        })

    def _request(self, method, path, **kwargs):
        """Make authenticated request"""
        url = f"{self.base_url}{path}"
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response.json()

    def get_status(self):
        """Get API status"""
        return self._request('GET', '/v1/status')

    def register_channel(self, youtube_id):
        """Register a YouTube channel"""
        return self._request('POST', '/v1/channels', json={
            'youtube_id': youtube_id
        })

    def list_channels(self):
        """List all channels"""
        return self._request('GET', '/v1/channels')

    def get_channel(self, channel_id):
        """Get channel details"""
        return self._request('GET', f'/v1/channels/{channel_id}')

    def get_channel_videos(self, channel_id, limit=50, **filters):
        """Get videos for a channel"""
        params = {'limit': limit, **filters}
        return self._request('GET', f'/v1/channels/{channel_id}/videos', params=params)

    def trigger_backfill(self, channel_id):
        """Trigger channel backfill"""
        return self._request('POST', f'/v1/channels/{channel_id}/backfill')

    def create_api_key(self, name, **kwargs):
        """Create a new API key"""
        data = {'name': name, **kwargs}
        return self._request('POST', '/v1/api_keys', json=data)

    def create_webhook(self, url, events=None, description=None):
        """Create webhook endpoint"""
        data = {'url': url}
        if events:
            data['events'] = events
        if description:
            data['description'] = description
        return self._request('POST', '/v1/webhooks/endpoints', json=data)

    def list_webhooks(self):
        """List webhook endpoints"""
        return self._request('GET', '/v1/webhooks/endpoints')

    @staticmethod
    def verify_webhook_signature(payload_body, signature_header, secret):
        """Verify webhook signature"""
        if isinstance(payload_body, str):
            payload_body = payload_body.encode('utf-8')
        
        expected_sig = hmac.new(
            secret.encode('utf-8'),
            payload_body,
            hashlib.sha256
        ).hexdigest()
        
        provided_sig = signature_header.replace('sha256=', '')
        
        return hmac.compare_digest(expected_sig, provided_sig)


def main():
    """Example usage"""
    # Configuration
    BASE_URL = os.getenv('YT_TRACKER_URL', 'http://localhost:4000')
    API_KEY = os.getenv('YT_TRACKER_API_KEY', 'yttr_YOUR_KEY_HERE')
    
    # Initialize client
    client = YtTrackerClient(BASE_URL, API_KEY)
    
    # Check API status
    print("📡 Checking API status...")
    status = client.get_status()
    print(f"   Status: {status['data']['status']}")
    print(f"   Version: {status['data']['version']}")
    print()
    
    # Register a channel (example: Fireship)
    youtube_id = "UCsBjURrPoezykLs9EqgamOA"
    print(f"📺 Registering channel: {youtube_id}")
    try:
        channel = client.register_channel(youtube_id)
        print(f"   ✅ Channel registered: {channel['data']['title']}")
        channel_id = channel['data']['id']
        print()
        
        # Get channel videos
        print("🎥 Fetching recent videos...")
        videos = client.get_channel_videos(channel_id, limit=5)
        for video in videos['data']:
            print(f"   - {video['title']}")
        print()
        
    except requests.HTTPError as e:
        print(f"   ❌ Error: {e.response.json()}")
        print()
    
    # List all channels
    print("📋 Listing all channels...")
    channels = client.list_channels()
    print(f"   Total channels: {len(channels['data'])}")
    print()
    
    # Example webhook verification
    print("🔐 Example webhook verification:")
    webhook_secret = "test_secret_12345"
    payload = json.dumps({
        "video_id": "abc-123",
        "youtube_id": "dQw4w9WgXcQ",
        "title": "Test Video"
    })
    
    signature = hmac.new(
        webhook_secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    is_valid = client.verify_webhook_signature(
        payload.encode('utf-8'),
        f"sha256={signature}",
        webhook_secret
    )
    print(f"   Signature valid: {is_valid}")


if __name__ == '__main__':
    main()
