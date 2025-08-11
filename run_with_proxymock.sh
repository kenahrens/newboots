#!/bin/bash
set -e

# Ensure the script is run from the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

cleanup() {
    kill $APP_PID 2>/dev/null || true
    kill $PROXYMOCK_PID 2>/dev/null || true
    wait $APP_PID 2>/dev/null || true
    wait $PROXYMOCK_PID 2>/dev/null || true
}
trap cleanup EXIT

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
export MONGODB_HOST="localhost" MYSQL_HOST="localhost"

rm -rf verification/
export JAVA_HOME="/opt/homebrew/Cellar/openjdk/24.0.2/libexec/openjdk.jdk/Contents/Home"
proxymock certs --jks

proxymock record --out verification &
PROXYMOCK_PID=$!

unset JAVA_TOOL_OPTIONS
rm -rf target/
mvn clean package -DskipTests

export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=localhost -Dhttp.proxyPort=4140 -Dhttps.proxyHost=localhost -Dhttps.proxyPort=4140 -Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit"
java -jar target/newboots-0.0.1-SNAPSHOT.jar &
APP_PID=$!

sleep 15

for i in {1..30}; do
    if curl -s http://localhost:8080/healthz > /dev/null 2>&1; then
        break
    fi
    sleep 2
    if [ $i -eq 30 ]; then
        kill $APP_PID 2>/dev/null || true
        exit 1
    fi
done

curl -s http://localhost:8080/ > /dev/null
curl -s http://localhost:8080/healthz > /dev/null
curl -s "http://localhost:8080/greeting?name=ProxyTest" > /dev/null
curl -s http://localhost:8080/pets/types > /dev/null
curl -s "http://localhost:8080/pets/types?type=dog" > /dev/null
curl -s "http://localhost:8080/inventory/search?key=status&value=A" > /dev/null
curl -s http://localhost:8080/nasa > /dev/null 2>&1 || true
curl -s http://localhost:8080/spacex > /dev/null 2>&1 || true
curl -s "http://localhost:8080/number-to-words?number=42" > /dev/null 2>&1 || true
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"latitude": 40.7128, "longitude": -74.0060, "macAddress": "aa:bb:cc:dd:ee:ff", "ipv4": "192.168.1.100"}' \
     http://localhost:8080/location > /dev/null

if command -v grpcurl > /dev/null 2>&1; then
    grpcurl -d '{"latitude": 40.7128, "longitude": -74.0060, "macAddress": "aa:bb:cc:dd:ee:ff", "ipv4": "192.168.1.100"}' -plaintext localhost:9090 LocationService/EchoLocation > /dev/null || true
    grpcurl -plaintext localhost:9090 Health/Check > /dev/null || true
fi

sleep 5

if [ "$(ls -A verification/ 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "SUCCESS! Found recorded traffic:"
    ls -la verification/
else
    echo "No traffic files found"
    exit 1
fi
