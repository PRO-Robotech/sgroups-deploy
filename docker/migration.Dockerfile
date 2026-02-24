FROM debian:bookworm-slim
ARG GOOSE_VERSION=v3.24.3-fork.1
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && \
    GOOSE_ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64" || echo "${TARGETARCH}") && \
    wget -q -O /usr/local/bin/goose \
      "https://github.com/Morwran/goose/releases/download/${GOOSE_VERSION}/goose_linux_${GOOSE_ARCH}" && \
    chmod +x /usr/local/bin/goose && \
    apt-get purge -y wget && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
COPY sgroups/internal/sg-server/repository/pg/migrations/ /migrations/
ENTRYPOINT ["goose"]
