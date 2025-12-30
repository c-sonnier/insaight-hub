# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.5
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libsqlite3-0 \
    libvips \
    sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage
FROM base AS build

# Install build dependencies including Node.js for npm packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libyaml-dev \
    pkg-config \
    nodejs \
    npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install npm packages (DaisyUI for Tailwind)
COPY package.json package-lock.json ./
RUN npm ci

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage
FROM base

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Fix permissions
RUN mkdir -p storage log tmp/pids tmp/cache tmp/sockets db && \
    chown -R rails:rails /rails storage log tmp db && \
    chmod -R go+r /rails

USER rails:rails

EXPOSE 3000

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the Rails server
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
