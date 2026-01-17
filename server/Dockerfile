FROM rust:1.83-alpine AS builder

# Install musl-dev for static linking
RUN apk add --no-cache musl-dev

WORKDIR /usr/src/app
COPY . .
RUN cargo install --path .

FROM alpine:3.21

# Install curl for healthcheck and ca-certificates for HTTPS
RUN apk add --no-cache ca-certificates curl && \
    # Create non-root user for security
    adduser -D -u 1000 appuser

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
