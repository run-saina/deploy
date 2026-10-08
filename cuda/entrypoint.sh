#!/bin/sh
# Starts the Saina server on SAINA_PORT. If TUNNEL_TOKEN is set, also runs a Cloudflare
# tunnel connector, so the server is reachable through a hostname with no open ports.
set -eu
if [ -n "${TUNNEL_TOKEN:-}" ]; then
  # The token is read from the environment, never passed on the command line.
  cloudflared --no-autoupdate tunnel run &
fi
exec uvicorn saina.server:create_app --factory --host 0.0.0.0 --port "${SAINA_PORT:-8000}" \
  --workers 1 --no-access-log --no-server-header
