#!/usr/bin/env bash
# Record baseline traffic + Reactor Netty WebClient traffic using HTTP proxy

set -euo pipefail

echo "=== Recording Baseline + Reactor Netty Traffic with HTTP Proxy ==="
echo "Captures: All external APIs including Hugging Face (Reactor Netty)"

# Configuration
TS=$(date +%Y-%m-%d_%H-%M-%S)
OUT_DIR="proxymock/recorded-${TS}-reactor-netty"
HTTP_PROXY_PORT=4143
APP_PORT=8080
TRUSTSTORE_PATH="$HOME/.speedscale/certs/cacerts.jks"

# Check prerequisites
if [ ! -f "$TRUSTSTORE_PATH" ]; then
  echo "⚠️  WARNING: Truststore not found at $TRUSTSTORE_PATH"
  echo "   HTTPS calls may fail. Install proxymock truststore first."
fi

echo "📁 Recording to: $OUT_DIR"

# Start proxymock with HTTP proxy
echo "🚀 Starting proxymock (HTTP proxy on port $HTTP_PROXY_PORT)..."
proxymock start-recording-traffic \
  --app-port $APP_PORT \
  --proxy-in-port $HTTP_PROXY_PORT \
  --out-directory "$OUT_DIR" > proxymock-record.log 2>&1 &

sleep 3

# Cleanup function
cleanup() {
  echo "🛑 Stopping application and proxymock..."
  [ -n "${APP_PID:-}" ] && kill "$APP_PID" >/dev/null 2>&1 || true
  proxymock stop-recording-traffic >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Start application with HTTP/HTTPS proxy settings
# These are needed for Reactor Netty to honor proxy
JAVA_OPTS="-Dhttp.proxyHost=localhost -Dhttp.proxyPort=$HTTP_PROXY_PORT"
JAVA_OPTS="$JAVA_OPTS -Dhttps.proxyHost=localhost -Dhttps.proxyPort=$HTTP_PROXY_PORT"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=$TRUSTSTORE_PATH"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStorePassword=changeit"

echo "🔧 Starting application with HTTP proxy settings..."
mvn -q spring-boot:run -Dspring-boot.run.jvmArguments="$JAVA_OPTS" > app.log 2>&1 &
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

# Make test calls
echo "📡 Making test API calls..."
echo "  - Hugging Face Models (Reactor Netty)"
curl -s http://localhost:$APP_PORT/models/openai | jq -r '.[0].id' 2>/dev/null || echo "Reactor Netty API called"

echo "  - NASA APOD API"
curl -s http://localhost:$APP_PORT/nasa | jq -r '.title' 2>/dev/null || echo "NASA API called"

echo "  - SpaceX API"
curl -s http://localhost:$APP_PORT/spacex | jq -r '.[0].name' 2>/dev/null || echo "SpaceX API called"

echo "  - ZIP Download"
curl -s http://localhost:$APP_PORT/zip | jq -r '.message' 2>/dev/null || echo "ZIP endpoint called"

echo "  - Number Conversion (SOAP)"
curl -s "http://localhost:$APP_PORT/number-to-words?number=456" || echo "SOAP API called"

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
echo "💡 Key directories to check:"
echo "  - huggingface.co (Reactor Netty WebClient)"
echo "  - api.nasa.gov, api.spacexdata.com (Google HTTP Client)"