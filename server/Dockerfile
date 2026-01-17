FROM rust:1.83 AS builder
WORKDIR /usr/src/app
COPY . .
RUN cargo install --path .

FROM debian:bookworm-slim

# Install curl for healthcheck and ca-certificates for HTTPS
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/* && \
    # Create non-root user for security
    useradd -m -u 1000 -s /bin/bash appuser

COPY --from=builder /usr/local/cargo/bin/session-server /usr/local/bin/session-server
RUN chown appuser:appuser /usr/local/bin/session-server

# Switch to non-root user
USER appuser

EXPOSE 3000

# Graceful shutdown
STOPSIGNAL SIGTERM

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:3000/health || exit 1

CMD ["session-server"]
