FROM debian:bookworm-slim AS builder

ARG APTLY_VERSION=1.6.2
ARG DISTRO=bookworm

# Install prerequisites for fetching the upstream Aptly package
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gnupg \
      ca-certificates \
      wget \
      apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Add Aptly upstream repository and key
# https://github.com/aptly-dev/aptly?tab=readme-ov-file#upstream-debian-packages
RUN set -eux; \
    # Add the Aptly GPG key
    wget -qO - https://www.aptly.info/pubkey.txt | gpg --dearmor -o /usr/share/keyrings/aptly.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/aptly.gpg] http://repo.aptly.info/release ${DISTRO} main" > /etc/apt/sources.list.d/aptly.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends aptly=${APTLY_VERSION}* ; \
    apt-get install -y --no-install-recommends aptly-api=${APTLY_VERSION}* ; \
    # Clean up
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

FROM debian:bookworm-slim

COPY --from=builder /usr/bin/aptly /usr/bin/aptly

# Install runtime deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget \
      gnupg \
      ca-certificates \
      xz-utils \
      dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

# Create data directory
ENV APTLY_ROOT /var/lib/aptly
RUN mkdir -p "$APTLY_ROOT" && chown -R root:root "$APTLY_ROOT"

VOLUME ["/var/lib/aptly"]

EXPOSE 8080

ENTRYPOINT ["aptly"]
CMD ["serve", "-listen=:8080"]
