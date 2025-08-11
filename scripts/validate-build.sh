#!/bin/bash

# Validate that the build produces the expected JAR file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Read version from VERSION file
VERSION=$(cat VERSION | tr -d '\n\r')

echo "Expected JAR file: newboots-${VERSION}.jar"

# Try to build
echo "Building project..."
if ! mvn clean package -DskipTests -q; then
    echo "Build failed"
    exit 1
fi

# Check if JAR exists
JAR_FILE="target/newboots-${VERSION}.jar"
if [ -f "$JAR_FILE" ]; then
    echo "✅ JAR file found: $JAR_FILE"
    ls -lh "$JAR_FILE"
else
    echo "❌ Expected JAR file not found: $JAR_FILE"
    echo "Available JAR files in target/:"
    find target/ -name "*.jar" || echo "No JAR files found"
    exit 1
fi

echo "✅ Build validation successful"