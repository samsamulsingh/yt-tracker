# Authentication and Multi-Channel Tracking

## Overview

The YT Tracker now includes a complete authentication system that allows users to:

- **Register** for a new account
- **Login** with email and password
- **Track multiple YouTube channels** per user
- **Add/Remove channels** through a web interface
- **View only their own channels** in the dashboard

## Quick Start

### 1. Start the Server

```bash
mix phx.server
```

Visit `http://localhost:4000` - you'll be redirected to the login page.

### 2. Create an Account

1. Click "create a new account" on the login page
2. Enter your email and password (minimum 8 characters)
3. Click "Create an account"

### 3. Add YouTube Channels

After logging in:

1. Click the "Add Channel" button in the header
2. Enter a YouTube channel ID or URL:
   - Channel ID: `UCxxxxxxxxxxxxxxxxxxxxxxx`
   - Channel URL: `https://youtube.com/channel/UCxxx`
   - Username: `@channelname`
3. Click "Add Channel"

The system will fetch channel metadata from YouTube and start tracking it.

### 4. Monitor Your Channels

The dashboard shows:

- **Total channels** you're tracking
- **Monitored channels** with automated checking enabled
- **Recent videos** from all your channels
- **Enable/Disable** monitoring per channel

## Features

### User Authentication

- **Secure password hashing** with Bcrypt
- **Session management** with tokens
- **Protected routes** - login required for dashboard and channel management
- **Multi-tenant support** - each user belongs to a tenant

### Channel Management

- **Add channels** via web form
- **Auto-fetch metadata** from YouTube API
- **View all your channels** in one place
- **Remove channels** you no longer want to track
- **Per-user channel lists** - see only channels you added

### Automated Monitoring

- **Background jobs** check channels every 15 minutes
- **RSS polling** detects new videos automatically
- **Real-time updates** appear in the dashboard via LiveView
- **Configurable frequency** per channel

## Database Schema

### New Tables

#### users
- `id` - UUID primary key
- `email` - Unique email address
- `hashed_password` - Bcrypt hashed password
- `confirmed_at` - Email confirmation timestamp
- `tenant_id` - Foreign key to tenants table

#### user_tokens
- `id` - UUID primary key
- `user_id` - Foreign key to users
- `token` - Binary session token
- `context` - Token type ("session", etc.)
- `sent_to` - Email address (for confirmation tokens)

#### youtube_channels (updated)
- Added `user_id` - Foreign key to users
- Channels can now be associated with specific users

## API Reference

### Authentication Endpoints

#### POST /login
Login with email and password

```bash
curl -X POST http://localhost:4000/login \
  -d "user[email]=user@example.com" \
  -d "user[password]=yourpassword"
```

#### DELETE /logout
Logout current user

```bash
curl -X DELETE http://localhost:4000/logout \
  --cookie "session_cookie_here"
```

### LiveView Routes

- `/login` - Login page
- `/register` - Registration page
- `/` - Dashboard (requires auth)
- `/channels/new` - Add channel form (requires auth)

## Security Features

- **CSRF protection** on all forms
- **Password requirements**: minimum 8 characters
- **Bcrypt hashing** with salt
- **Session tokens** expire after 60 days
- **Protected routes** redirect to login if not authenticated

## Code Structure

### Authentication Context

```elixir
YtTracker.Accounts
├── User - User schema
├── UserToken - Session token schema
├── register_user/1 - Create new user
├── get_user_by_email_and_password/2 - Login
├── generate_user_session_token/1 - Create session
└── get_user_by_session_token/1 - Verify session
```

### LiveView Pages

```elixir
YtTrackerWeb
├── UserLoginLive - Login form
├── UserRegistrationLive - Registration form
├── DashboardLive - Main dashboard (auth required)
└── ChannelFormLive - Add/manage channels (auth required)
```

### Controllers

```elixir
YtTrackerWeb.UserSessionController
├── create/2 - Handle login POST
└── delete/2 - Handle logout
```

## Development

### Create Test User

```elixir
# In iex -S mix:
YtTracker.Accounts.register_user(%{
  email: "test@example.com",
  password: "password123"
})
```

### List All Users

```elixir
YtTracker.Repo.all(YtTracker.Accounts.User)
```

### Delete User

```elixir
user = YtTracker.Accounts.get_user_by_email("test@example.com")
YtTracker.Repo.delete(user)
```

## Customization

### Change Session Expiry

Edit `lib/yt_tracker/accounts/user_token.ex`:

```elixir
@session_validity_in_days 60  # Change this
```

### Change Password Requirements

Edit `lib/yt_tracker/accounts/user.ex`:

```elixir
def validate_password(changeset, opts) do
  changeset
  |> validate_required([:password])
  |> validate_length(:password, min: 8, max: 72)  # Adjust min/max
end
```

## Troubleshooting

### "You must log in to access this page"

Your session expired or you haven't logged in. Go to `/login`.

### "Invalid email or password"

Check your email and password are correct. Passwords are case-sensitive.

### Channel not showing up

Make sure you:
1. Are logged in
2. Added the channel while logged in
3. The channel ID is correct

### Can't see other users' channels

This is by design - each user only sees channels they added.

## Production Considerations

1. **Email Confirmation**: Currently disabled, add email service for production
2. **Password Reset**: Not implemented, add for production use
3. **HTTPS**: Use SSL/TLS in production
4. **Session Security**: Set secure cookie flags in production
5. **Rate Limiting**: Add rate limits to prevent abuse

## Next Steps

- [ ] Add email confirmation
- [ ] Implement password reset
- [ ] Add user profile page
- [ ] Allow sharing channels between users
- [ ] Add two-factor authentication
- [ ] Implement API keys per user

## License

See main project README for licensing information.
