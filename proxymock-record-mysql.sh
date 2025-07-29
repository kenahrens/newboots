#!/bin/bash

# Script to start proxymock recording with SOCKS proxy for MySQL traffic capture

set -e

# Configuration
PROXY_PORT=4140
APP_PORT=8080
OUTPUT_DIR="proxymock/recorded-mysql-$(date +%Y-%m-%d_%H-%M-%S)"

echo "🚀 Starting proxymock recording with SOCKS proxy for MySQL traffic..."
echo "📁 Output directory: $OUTPUT_DIR"
echo "🔌 SOCKS proxy port: $PROXY_PORT"
echo "🌐 Application port: $APP_PORT"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Start proxymock recording with SOCKS proxy
echo "📡 Starting proxymock recording..."
proxymock record \
    --proxy-in-port $PROXY_PORT \
    --app-port $APP_PORT \
    --out-directory "$OUTPUT_DIR"

echo ""
echo "✅ Proxymock recording started successfully!"
echo "🔧 Configure your application to use SOCKS proxy:"
echo "   Host: localhost"
echo "   Port: $PROXY_PORT"
echo "   Protocol: SOCKS5"
echo ""
echo "📝 To stop recording, run: make proxymock-stop" 