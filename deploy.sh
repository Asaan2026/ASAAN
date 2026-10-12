#!/bin/bash
# Pulled onto the server by the deploy workflow; rebuilds and restarts the app.
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/asaan}"
cd "$APP_DIR"

echo "[deploy] $(date -u '+%Y-%m-%dT%H:%M:%SZ') fetching latest source"
git fetch --prune origin
git reset --hard origin/main

echo "[deploy] rebuilding application image"
docker build -t asaan_online_store_app:latest .

echo "[deploy] starting services (database first)"
docker compose up -d

echo "[deploy] pruning old images"
docker image prune -f >/dev/null 2>&1 || true

echo "[deploy] done - $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
