#!/bin/bash

# Build the project and update K8s manifests with the version

set -e

echo "Building project..."
mvn clean package

# Read version from VERSION file
if [ ! -f "VERSION" ]; then
    echo "Error: VERSION file not found"
    exit 1
fi

VERSION=$(cat VERSION | tr -d '\n\r')

if [ -z "$VERSION" ]; then
    echo "Error: VERSION file is empty"
    exit 1
fi

echo "Project version: $VERSION"

# Update version patch file
./scripts/update-k8s-version.sh

# Build Docker images with version tag
echo "Building Docker images with version $VERSION..."
docker build -t ghcr.io/kenahrens/newboots-server:$VERSION -f Dockerfile .
docker build -t ghcr.io/kenahrens/newboots-client:$VERSION -f Dockerfile.client .

# Also tag as latest for convenience
docker tag ghcr.io/kenahrens/newboots-server:$VERSION ghcr.io/kenahrens/newboots-server:latest
docker tag ghcr.io/kenahrens/newboots-client:$VERSION ghcr.io/kenahrens/newboots-client:latest

echo "Build complete. Version: $VERSION"
echo "To deploy, run: kubectl apply -k k8s/overlays/default/"