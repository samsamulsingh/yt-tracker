# Contributing to YT Tracker

Thank you for your interest in contributing to YT Tracker! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/yt_tracker.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Set up the development environment (see README.md)

## Development Workflow

### Code Style

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Run `mix format` before committing
- Run `mix credo` to check for code issues

### Testing

- Write tests for all new features
- Ensure all tests pass: `mix test`
- Maintain or improve code coverage
- Add integration tests for API endpoints
- Use descriptive test names

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add video search endpoint
fix: correct rate limiting calculation
docs: update API documentation
test: add tests for webhook signing
refactor: improve channel registration flow
```

### Pull Requests

1. Update documentation if needed
2. Add tests for new functionality
3. Ensure `mix test` and `mix credo` pass
4. Update CHANGELOG.md
5. Submit PR with clear description

## Code Organization

- `lib/yt_tracker/` - Core business logic contexts
- `lib/yt_tracker_web/` - Web layer (controllers, plugs)
- `lib/yt_tracker/workers/` - Oban background jobs
- `priv/repo/migrations/` - Database migrations
- `test/` - Test files mirroring lib/ structure

## Reporting Issues

- Use GitHub Issues
- Provide clear description
- Include steps to reproduce
- Add relevant error messages/logs
- Specify Elixir/Phoenix versions

## Questions?

Open an issue or discussion on GitHub.

Thank you for contributing! 🎉
