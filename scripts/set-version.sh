#!/bin/bash

# Script to set a new version across the project

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    echo "Example: $0 1.1.0-SNAPSHOT"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (basic check)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9]+)?$ ]]; then
    echo "Warning: Version format may be invalid. Expected format: X.Y.Z or X.Y.Z-SUFFIX"
    echo "Proceeding anyway..."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "Setting version to: $NEW_VERSION"

# Update VERSION file
echo "$NEW_VERSION" > VERSION
echo "Updated VERSION file"

# Sync to pom.xml
./scripts/sync-version.sh

# Update K8s manifests
./scripts/update-k8s-version.sh

echo ""
echo "Version updated to $NEW_VERSION across:"
echo "- VERSION file"
echo "- pom.xml"  
echo "- Kubernetes manifests"
echo ""
echo "Next steps:"
echo "1. Build and push images: make docker"
echo "2. Deploy: make deploy"