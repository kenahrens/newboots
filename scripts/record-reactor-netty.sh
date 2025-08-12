#!/usr/bin/env bash
# Record Reactor Netty WebClient traffic using reverse proxy
# Demonstrates proxymock recording for HTTP clients that don't work well with traditional proxies

set -euo pipefail

echo "=== Recording Reactor Netty Traffic with Reverse Proxy ==="
echo "Captures: Hugging Face API traffic via Reactor Netty WebClient"

# Configuration
TS=$(date +%Y-%m-%d_%H-%M-%S)
OUT_DIR="proxymock/recorded-${TS}"
APP_PORT=8080
REVERSE_PROXY_PORT=65443
TRUSTSTORE_PATH="$HOME/.speedscale/certs/cacerts.jks"

# Check prerequisites
if [ ! -f "$TRUSTSTORE_PATH" ]; then
  echo "⚠️  WARNING: Truststore not found at $TRUSTSTORE_PATH"
  echo "   Install proxymock truststore for HTTPS interception to work properly."
fi

echo "📁 Recording to: $OUT_DIR"

# Start proxymock with reverse proxy for Hugging Face
echo "🚀 Starting proxymock (reverse proxy on port $REVERSE_PROXY_PORT -> huggingface.co:443)..."
proxymock record \
  --reverse-proxy $REVERSE_PROXY_PORT=huggingface.co:443 \
  --app-port $APP_PORT \
  --out "$OUT_DIR" > proxymock-record.log 2>&1 &
PROXYMOCK_PID=$!

sleep 3

# Cleanup function
cleanup() {
  echo "🛑 Stopping application and proxymock..."
  [ -n "${APP_PID:-}" ] && kill "$APP_PID" >/dev/null 2>&1 || true
  [ -n "${PROXYMOCK_PID:-}" ] && kill "$PROXYMOCK_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Start application with environment variable override for Hugging Face endpoint
# This redirects Hugging Face API calls to the proxymock reverse proxy
# Use HTTP to avoid SSL certificate complications - proxymock handles HTTPS to target
export HF_API_BASE="http://localhost:$REVERSE_PROXY_PORT"

echo "🔧 Starting application with reverse proxy configuration..."
echo "   HF_API_BASE=$HF_API_BASE (points to reverse proxy)"
mvn -q spring-boot:run > app.log 2>&1 &
APP_PID=$!

# Wait for app to be ready
echo "⏳ Waiting for application to start..."
for i in {1..30}; do
  if curl -s http://localhost:$APP_PORT/healthz >/dev/null 2>&1; then
    echo "✅ Application ready!"
    break
  fi
  [ $i -eq 30 ] && echo "❌ Application failed to start" && exit 1
  sleep 2
done

# Make test call to trigger Reactor Netty WebClient
echo "📡 Making test API call..."
echo "  - Hugging Face Models API (Reactor Netty WebClient)"
curl -s http://localhost:$APP_PORT/models/openai | jq -r '.[0].id' 2>/dev/null || echo "Reactor Netty API called"

# Wait for recordings to complete
sleep 3

# Show results
echo ""
echo "📊 Recording Summary:"
echo "Recorded hosts:"
find "$OUT_DIR" -type d -mindepth 1 -maxdepth 1 2>/dev/null | xargs -n1 basename | sed 's/^/  - /' || echo "  No recordings yet"

echo ""
echo "✅ Recording complete!"
echo "📁 Recordings saved to: $OUT_DIR"
echo ""
echo "💡 Check the huggingface.co directory for captured Reactor Netty traffic"