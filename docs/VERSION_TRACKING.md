# Version Tracking for Kubernetes Deployments

This document explains how version tracking works for Kubernetes deployments in the newboots project.

## Overview

The project uses a dedicated `VERSION` file as the single source of truth for versioning. This version is automatically propagated to:
- Docker image tags
- Kubernetes deployment manifests
- Maven pom.xml (via sync scripts)

## How It Works

1. **Version Source**: The version is defined in the `VERSION` file (currently `0.0.1-SNAPSHOT`)

2. **Version Update Script**: `scripts/update-k8s-version.sh`
   - Reads the version from the `VERSION` file
   - Generates `k8s/overlays/default/version-patch.yaml` with the correct image versions

3. **Kustomize Integration**: The version patch is applied via Kustomize when deploying

4. **Version Synchronization**: `scripts/sync-version.sh` keeps `pom.xml` in sync with the `VERSION` file

## Usage

### Setting a New Version
```bash
# Set a new version across the entire project
./scripts/set-version.sh 1.0.0

# Or using Make
make set-version NEW_VERSION=1.0.0
```

### Manual Update
```bash
# Update K8s manifests with current version
./scripts/update-k8s-version.sh

# Or using Make
make update-k8s-version

# Sync VERSION file to pom.xml
make sync-version
```

### Build and Deploy with Version
```bash
# Build Docker images with current version
make docker

# Deploy with updated version
make deploy
```

### Check Current Version
```bash
make version
```

## CI/CD Integration

The GitHub Actions workflow `.github/workflows/version-update.yml` automatically:
- Triggers when `VERSION` file is updated on the main branch
- Updates the K8s version patch file
- Commits the changes back to the repository

## Version File Locations

- **Version Source**: `VERSION` file (single source of truth)
- **Generated Patch**: `k8s/overlays/default/version-patch.yaml` (gitignored)
- **Base Manifests**: `k8s/base/deploy.yaml`, `k8s/base/client-deploy.yaml`
- **Synchronized**: `pom.xml` - `<version>` tag (updated via sync scripts)

## Best Practices

1. Always update the version in the `VERSION` file when releasing
2. Use semantic versioning (e.g., 1.0.0, 1.1.0-SNAPSHOT)
3. The version patch file is generated and should not be committed
4. Run `make deploy` to ensure version tracking is applied
5. Use `make set-version` to update versions consistently across all files

## Example Workflow

1. Set a new version:
   ```bash
   make set-version NEW_VERSION=1.0.0
   ```
   This updates:
   - `VERSION` file
   - `pom.xml`
   - Kubernetes manifests

2. Build and push images:
   ```bash
   make docker
   ```

3. Deploy to Kubernetes:
   ```bash
   make deploy
   ```

The deployment will use images tagged with `1.0.0` instead of `latest`.