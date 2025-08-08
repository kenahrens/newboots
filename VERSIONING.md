# Versioning and Multi-Architecture Build Strategy

## Overview

This project uses semantic versioning with automatic build numbers for Docker images and supports multi-architecture builds for both AMD64 and ARM64 platforms.

## Version Format

- **Format:** `vMAJOR.MINOR.BUILD_NUMBER`
- **Example:** `v1.0.42`
- **Build Number:** Automatically incremented based on git commit count

## Supported Architectures

- **linux/amd64** - Intel/AMD 64-bit processors
- **linux/arm64** - ARM 64-bit processors (Apple Silicon, AWS Graviton, etc.)

## CI/CD Pipeline

### Automatic Versioning
The GitHub Actions CI pipeline automatically generates versions:
- **Main branch pushes:** `v1.0.{run_number}`
- **Pull requests:** `v1.0.{run_number}-pr{pr_number}`

### Image Tags
Each build produces two tags per image:
1. **Versioned tag:** `ghcr.io/kenahrens/newboots-server:v1.0.42`
2. **Latest tag:** `ghcr.io/kenahrens/newboots-server:latest`

## Local Development

### Check Current Version
```bash
make version
```

### Build Multi-Architecture Images (requires push access)
```bash
make docker
```

### Build Local Single-Architecture Images
```bash
make docker-local
```

### Deploy Specific Version to Kubernetes
```bash
make deploy-version FULL_VERSION=v1.0.42
```

## Docker Commands

### Manual Multi-Architecture Build
```bash
# Setup buildx (one time)
docker buildx create --use

# Build and push multi-arch
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.server \
  -t ghcr.io/kenahrens/newboots-server:v1.0.42 \
  --push .
```

### Local Development Build
```bash
# Build for current architecture only
docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:v1.0.42-local .
```

## Kubernetes Deployment Strategy

### Default Deployment
- Uses `:latest` tag with `imagePullPolicy: Always`
- Automatically pulls newest image on pod restart
- Good for development environments

### Production Deployment
- Use specific version tags: `v1.0.42`
- Set `imagePullPolicy: IfNotPresent`
- Ensures predictable deployments

### Example Version-Specific Deployment
```yaml
spec:
  containers:
    - name: newboots-server
      image: ghcr.io/kenahrens/newboots-server:v1.0.42
      imagePullPolicy: IfNotPresent
```

## Architecture Compatibility

The multi-architecture images ensure compatibility across:
- **Development:** Apple Silicon Macs (M1/M2/M3)
- **CI/CD:** GitHub Actions runners (AMD64)
- **Production:** AWS Graviton instances, Azure ARM, GKE ARM nodes
- **Local Testing:** Colima, Docker Desktop, etc.

## Best Practices

1. **Use versioned tags in production**
2. **Test multi-arch builds before release**  
3. **Document breaking changes in version bumps**
4. **Keep `:latest` tag for development only**
5. **Use `imagePullPolicy: IfNotPresent` with versioned tags**

## Troubleshooting

### Architecture Mismatch
If you see `exec format error`, you're running the wrong architecture:
```bash
# Check image architecture
docker inspect ghcr.io/kenahrens/newboots-server:latest | grep Architecture

# Force pull specific architecture
docker pull --platform linux/amd64 ghcr.io/kenahrens/newboots-server:latest
```

### Build Issues
```bash
# Reset Docker buildx
docker buildx rm --all
docker buildx create --use

# Check buildx status
docker buildx ls
```