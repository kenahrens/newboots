#!/usr/bin/env bash
# Record baseline traffic + MySQL database calls using SOCKS proxy

set -euo pipefail

echo "=== Recording Baseline + MySQL Traffic with SOCKS Proxy ==="
echo "Captures: External APIs (NASA, SpaceX) + MySQL database traffic"

# Configuration
TS=$(date +%Y-%m-%d_%H-%M-%S)
OUT_DIR="proxymock/recorded-${TS}-baseline-mysql"
SOCKS_PORT=4140
APP_PORT=8080
TRUSTSTORE_PATH="$HOME/.speedscale/certs/cacerts.jks"

# Check prerequisites
if [ ! -f "$TRUSTSTORE_PATH" ]; then
  echo "⚠️  WARNING: Truststore not found at $TRUSTSTORE_PATH"
  echo "   HTTPS calls may fail. Install proxymock truststore first."
fi

# Check if MySQL is running
if ! docker ps | grep -q mysql; then
  echo "⚠️  MySQL container not running. Starting databases..."
  make databases-up
  sleep 5
fi

echo "📁 Recording to: $OUT_DIR"
mkdir -p "$OUT_DIR"

# Start proxymock with custom hostname for MySQL
echo "🚀 Starting proxymock (SOCKS proxy on port $SOCKS_PORT)..."
echo "   Configuring MySQL to route through proxy..."
proxymock record \
  --out "$OUT_DIR" \
  --app-port $APP_PORT \
  --add-host mysql-db=127.0.0.1:3306 > proxymock-record.log 2>&1 &
PM_PID=$!
sleep 3

# Cleanup function
cleanup() {
  echo "🛑 Stopping application and proxymock..."
  [ -n "${APP_PID:-}" ] && kill "$APP_PID" >/dev/null 2>&1 || true
  kill "$PM_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Start application with SOCKS proxy and custom MySQL host
JAVA_OPTS="-DsocksProxyHost=localhost -DsocksProxyPort=$SOCKS_PORT"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=$TRUSTSTORE_PATH"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStorePassword=changeit"
# Override MySQL host to route through proxy
JAVA_OPTS="$JAVA_OPTS -Dspring.datasource.url=jdbc:mysql://mysql-db:3306/pets?createDatabaseIfNotExist=true"

echo "🔧 Starting application with SOCKS proxy and MySQL routing..."
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
echo "  - Pet breeds (MySQL query)"
curl -s http://localhost:$APP_PORT/breeds | jq -r '.[0].breed' 2>/dev/null || echo "MySQL query executed"

echo "  - NASA APOD API"
curl -s http://localhost:$APP_PORT/nasa | jq -r '.title' 2>/dev/null || echo "NASA API called"

echo "  - SpaceX API"
curl -s http://localhost:$APP_PORT/spacex | jq -r '.[0].name' 2>/dev/null || echo "SpaceX API called"

echo "  - Creating new pet breed (MySQL insert)"
curl -s -X POST http://localhost:$APP_PORT/breeds \
  -H "Content-Type: application/json" \
  -d '{"breed":"Test Breed","averageWeight":50}' || echo "MySQL insert executed"

# Wait for recordings to complete
sleep 3

# Show results
echo ""
echo "📊 Recording Summary:"
echo "Recorded hosts:"
ls -1 "$OUT_DIR" 2>/dev/null | sed 's/^/  - /' || echo "  No recordings yet"

echo ""
echo "✅ Recording complete!"
echo "📁 Recordings saved to: $OUT_DIR"
echo ""
echo "💡 Tip: Look for 'mysql-db' directory for database traffic"