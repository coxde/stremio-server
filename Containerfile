# Jellyfin FFMPEG package
ARG OS_VERSION=trixie
ARG PACKAGE_ARCH=amd64
ARG FFMPEG_PACKAGE=jellyfin-ffmpeg7

# Build stage
FROM node:lts-trixie AS builder

# Install build dependencies
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests --yes \
    ca-certificates \
    curl \
    jq \
&& rm -rf /var/cache/apt/archives* /var/lib/apt/lists/*

# Fetch server.js version from latest tagged version on Docker Hub
WORKDIR /tmp
RUN VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/stremio/server/tags/" | jq -r '.results[].name' | grep -v 'latest' | sort -V | tail -n 1) && \
    echo "Using version: ${VERSION}" && \
    curl -fL "https://dl.strem.io/server/${VERSION}/desktop/server.js" -o server.js

# Final stage
FROM node:lts-trixie

ARG OS_VERSION
ARG PACKAGE_ARCH
ARG FFMPEG_PACKAGE

# Install runtime dependencies
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests --yes \
    ca-certificates \
    curl \
    gnupg \
 && curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg \
 && cat <<EOF > /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/debian
Suites: ${OS_VERSION}
Components: main
Architectures: ${PACKAGE_ARCH}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests --yes \
    ${FFMPEG_PACKAGE} \
 && apt-get remove gnupg apt-transport-https --yes \
 && apt-get clean autoclean --yes \
 && apt-get autoremove --yes \
 && rm -rf /var/cache/apt/archives* /var/lib/apt/lists/*

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
