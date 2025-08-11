#!/bin/bash

# Script to synchronize version between VERSION file and pom.xml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

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

echo "Synchronizing version: $VERSION"

# Update pom.xml with the version from VERSION file
if [ -f "pom.xml" ]; then
    # Use sed to update the version in pom.xml
    # This updates the first <version> tag after <artifactId>newboots</artifactId>
    sed -i.backup "/<artifactId>newboots<\/artifactId>/{
        N
        s/<version>[^<]*<\/version>/<version>$VERSION<\/version>/
    }" pom.xml
    
    if [ -f "pom.xml.backup" ]; then
        rm pom.xml.backup
    fi
    
    echo "Updated pom.xml version to $VERSION"
else
    echo "Warning: pom.xml not found"
fi

echo "Version synchronization complete"