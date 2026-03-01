# Build stage
FROM node:current-alpine@sha256:18e02657e2a2cc3a87210ee421e9769ff28a1ac824865d64f74d6d2d59f74b6b AS builder

# Install build dependencies
RUN apk add --no-cache curl jq jellyfin-ffmpeg

# Fetch server.js version from latest tagged version on Docker Hub
WORKDIR /tmp
RUN VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/stremio/server/tags/" | jq -r '.results[].name' | grep -v 'latest' | sort -V | tail -n 1) && \
    echo "Using version: ${VERSION}" && \
    curl -fL "https://dl.strem.io/server/${VERSION}/desktop/server.js" -o server.js

# Final stage
FROM node:current-alpine@sha256:18e02657e2a2cc3a87210ee421e9769ff28a1ac824865d64f74d6d2d59f74b6b

# Install runtime dependencies
RUN apk add --no-cache jellyfin-ffmpeg

# Copy server.js from builder stage
COPY --from=builder /tmp/server.js ./

# Custom ENV options
ENV FFMPEG_BIN=
ENV FFPROBE_BIN=
ENV APP_PATH=
ENV NODE_ENV=production
ENV NO_CORS=1
ENV CASTING_DISABLED=1

# Cache folder
VOLUME ["/root/.stremio-server"]

# Expose default ports
EXPOSE 11470 12470

# Start stremio server
ENTRYPOINT [ "node", "server.js" ]
