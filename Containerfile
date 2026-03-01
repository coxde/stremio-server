# Build stage
FROM node:lts-slim@sha256:e8e2e91b1378f83c5b2dd15f0247f34110e2fe895f6ca7719dbb780f929368eb AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq

# Fetch server.js version from latest tagged version on Docker Hub
WORKDIR /tmp
RUN VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/stremio/server/tags/" | jq -r '.results[].name' | grep -v 'latest' | sort -V | tail -n 1) && \
    echo "Using version: ${VERSION}" && \
    curl -fL "https://dl.strem.io/server/${VERSION}/desktop/server.js" -o server.js

# Final stage
FROM node:lts-slim@sha256:e8e2e91b1378f83c5b2dd15f0247f34110e2fe895f6ca7719dbb780f929368eb

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    jellyfin-ffmpeg7

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
