FROM elixir:1.16-alpine

# Install build and runtime dependencies (node for assets + build tools)
RUN apk add --no-cache build-base git nodejs npm openssl ncurses-libs libstdc++

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files and fetch Elixir deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy application files
COPY config config
COPY lib lib
COPY priv priv

# Copy assets and install JS dependencies, then build assets
COPY assets/package*.json assets/
COPY assets/ assets/
RUN cd assets && npm ci --silent

# Build and deploy assets for production (tailwind + esbuild + phx.digest)
RUN MIX_ENV=prod mix assets.deploy

# Compile and build release
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

# Create non-root user
RUN addgroup -g 1000 yt_tracker && \
    adduser -D -u 1000 -G yt_tracker yt_tracker && \
    chown -R yt_tracker:yt_tracker /app

USER yt_tracker

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=prod

# Start the application
CMD ["_build/prod/rel/yt_tracker/bin/yt_tracker", "start"]
