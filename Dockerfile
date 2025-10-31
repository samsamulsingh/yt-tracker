FROM elixir:1.16-alpine AS build

# Install build dependencies (including node for assets)
RUN apk add --no-cache build-base git nodejs npm

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
# We copy package files first so npm can install cached layers when deps don't change
COPY assets/package*.json assets/
COPY assets/ assets/
RUN cd assets && npm ci --silent

# Build and deploy assets for production (tailwind + esbuild + phx.digest)
RUN MIX_ENV=prod mix assets.deploy

# Compile and build release
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

# Production stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/yt_tracker ./

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
CMD ["bin/yt_tracker", "start"]
