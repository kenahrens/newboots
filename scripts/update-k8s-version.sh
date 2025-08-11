#!/bin/bash

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

echo "Updating Kubernetes manifests with version: $VERSION"

# Update kustomization.yaml to use the specific version
cat > k8s/overlays/default/version-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: newboots-server
spec:
  template:
    spec:
      containers:
      - name: newboots-server
        image: ghcr.io/kenahrens/newboots-server:$VERSION
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: newboots-client
spec:
  template:
    spec:
      containers:
      - name: newboots-client
        image: ghcr.io/kenahrens/newboots-client:$VERSION
EOF

echo "Version patch file created at k8s/overlays/default/version-patch.yaml"
echo "Version: $VERSION"