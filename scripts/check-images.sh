#!/bin/bash

# Check if Docker images exist in GitHub Container Registry

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Read version from VERSION file
VERSION=$(cat VERSION | tr -d '\n\r')

echo "Checking if images exist for version: $VERSION"
echo

# Check server image
echo "🔍 Checking ghcr.io/kenahrens/newboots-server:$VERSION"
if docker manifest inspect ghcr.io/kenahrens/newboots-server:$VERSION >/dev/null 2>&1; then
    echo "✅ Server image exists"
else
    echo "❌ Server image not found"
fi

# Check client image  
echo "🔍 Checking ghcr.io/kenahrens/newboots-client:$VERSION"
if docker manifest inspect ghcr.io/kenahrens/newboots-client:$VERSION >/dev/null 2>&1; then
    echo "✅ Client image exists"
else
    echo "❌ Client image not found"
fi

echo
echo "Note: Images may not be publicly accessible but can still exist in the registry."
echo "If both images exist, you can deploy with: make deploy"