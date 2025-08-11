#!/bin/bash

# Temporarily use latest tag instead of version tag

echo "Creating version patch to use 'latest' tag..."

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
        image: ghcr.io/kenahrens/newboots-server:latest
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
        image: ghcr.io/kenahrens/newboots-client:latest
EOF

echo "Version patch updated to use 'latest' tag"