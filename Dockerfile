# Multi-stage build to package substreams-sink-sql alongside ClickHouse Server
# Stage 1: get the substreams-sink-sql binary
FROM ghcr.io/streamingfast/substreams-sink-sql:latest AS sink

# Stage 2: final image running ClickHouse Server with the binary available
FROM clickhouse/clickhouse-server:latest

USER root

# Copy the substreams-sink-sql binary into PATH
# Note: path in the source image may change over time, but /app/substreams-sink-sql is the
# common location used by upstream images. Adjust if needed.
COPY --from=sink /app/substreams-sink-sql /usr/local/bin/substreams-sink-sql
RUN chmod +x /usr/local/bin/substreams-sink-sql

# Configure ClickHouse logger to hide debug/trace by setting level to 'information'
COPY ./clickhouse-logger.xml /etc/clickhouse-server/config.d/zz-logger.xml

# Configure ClickHouse to allow access without user/password (default user with empty password)
COPY ./clickhouse-no-auth.xml /etc/clickhouse-server/users.d/zz-no-auth.xml

# Expose common ClickHouse ports
# 9000  - native client
# 8123  - HTTP interface
# 9009  - inter-server communication
EXPOSE 9000 8123 9009

# Basic healthcheck to ensure ClickHouse server responds
HEALTHCHECK --interval=30s --timeout=3s --retries=5 CMD clickhouse-client --host=localhost --query="SELECT 1" >/dev/null 2>&1 || exit 1

# Use the default entrypoint and command provided by clickhouse/clickhouse-server
# This image will start ClickHouse Server, while the substreams-sink-sql binary is
# available inside the container for use (e.g., via `docker exec`).
