IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest
GIT_VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD)
GIT_FULL_VERSION ?= $(GIT_VERSION).$(BUILD_NUMBER)
VERSION ?= $(shell cat VERSION 2>/dev/null || echo "0.0.1-SNAPSHOT")
SOCKS_PROXY ?= -DsocksProxyHost=localhost -DsocksProxyPort=4140
TRUSTSTORE ?= -Djavax.net.ssl.trustStore=$(HOME)/.speedscale/certs/cacerts.jks

.PHONY: test jar docker run lint deploy patch check-k8s-image docker-client docker-server delete clean test-endpoints run-proxy docker-compose-up docker-compose-down version set-version sync-version update-k8s-version validate-build docker-build-local check-images

test:
	mvn test

jar:
	mvn clean package

run:
	mvn spring-boot:run

run-proxy:
	JAVA_TOOL_OPTIONS="$(SOCKS_PROXY) $(TRUSTSTORE)" mvn spring-boot:run

docker-compose-up:
	docker compose up -d

docker-compose-down:
	docker compose down

docker-compose-logs:
	docker compose logs -f

docker-compose-test:
	docker compose up -d
	sleep 30
	./scripts/test_endpoints.sh
	docker compose down

# Database management
databases-up:
	docker compose -f docker-compose-databases.yml up -d

databases-down:
	docker compose -f docker-compose-databases.yml down

databases-logs:
	docker compose -f docker-compose-databases.yml logs -f

databases-clean:
	docker compose -f docker-compose-databases.yml down -v

# Local development
dev: databases-up
	@echo "Starting databases..."
	@echo "Waiting for databases to be ready..."
	@sleep 10
	@echo "Databases are ready!"
	@echo "You can now run: mvn spring-boot:run"

dev-clean: databases-down
	@echo "Databases stopped and cleaned up"

# Proxymock recording
proxymock-record:
	@echo "Starting proxymock recording with SOCKS proxy on port 4140..."
	proxymock record -vv

proxymock-stop:
	@echo "Stopping proxymock recording..."
	pkill -f proxymock

# Development with proxymock (complete workflow)
dev-proxy: databases-up
	@echo "Starting databases and proxymock recording..."
	@echo "Setting JAVA_TOOL_OPTIONS for SOCKS proxy and trust store..."
	@echo "Setting custom hostnames for proxymock grouping..."
	@export JAVA_TOOL_OPTIONS="-DsocksProxyHost=localhost -DsocksProxyPort=4140 -Djavax.net.ssl.trustStore=$$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit" && \
	export MONGODB_HOST="localhost" && \
	export MYSQL_HOST="mysql" && \
	echo "JAVA_TOOL_OPTIONS: $$JAVA_TOOL_OPTIONS" && \
	echo "MONGODB_HOST: $$MONGODB_HOST" && \
	echo "MYSQL_HOST: $$MYSQL_HOST" && \
	echo "Starting application with proxy..." && \
	mvn spring-boot:run

dev-proxy-clean: proxymock-stop databases-down
	@echo "Proxymock recording stopped and databases cleaned up"

# Multi-architecture Docker builds
docker-client:
	docker buildx build --platform linux/amd64,linux/arm64 \
		-f Dockerfile.client \
		-t ghcr.io/kenahrens/newboots-client:latest \
		-t ghcr.io/kenahrens/newboots-client:$(VERSION) \
		--push .

docker-server:
	docker buildx build --platform linux/amd64,linux/arm64 \
		-f Dockerfile.server \
		-t ghcr.io/kenahrens/newboots-server:latest \
		-t ghcr.io/kenahrens/newboots-server:$(VERSION) \
		--push .

# Local single-arch builds (for development)
docker-client-local:
	docker build -f Dockerfile.client -t ghcr.io/kenahrens/newboots-client:$(VERSION)-local .

docker-server-local:
	docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:$(VERSION)-local .

docker: docker-client docker-server
	@echo "Built and pushed multi-arch images with version $(VERSION)"

docker-local: docker-client-local docker-server-local
	@echo "Built local images with version $(VERSION)-local"

lint:
	mvn checkstyle:check

update-k8s-version:
	@echo "Updating K8s manifests with version: $(VERSION)"
	@./scripts/update-k8s-version.sh

deploy: update-k8s-version
	kubectl apply -k k8s/overlays/default

deploy-version:
	@echo "Deploying version $(GIT_FULL_VERSION)"
	@sed 's|ghcr.io/kenahrens/newboots-server:latest|ghcr.io/kenahrens/newboots-server:$(GIT_FULL_VERSION)|g' k8s/base/deploy.yaml | kubectl apply -f -

patch:
	kubectl patch deployment newboots-server -n default --patch-file k8s/patch-inject-newboots.yaml

check-k8s-image:
	grep -E 'image: ghcr.io/kenahrens/newboots-(client|server):latest' k8s/base/deploy.yaml

delete:
	kubectl delete deployment newboots-server -n default || true

clean:
	mvn clean

test-endpoints:
	./scripts/test_endpoints.sh

version:
	@echo "Version (from VERSION file): $(VERSION)"
	@echo "Git version: $(GIT_VERSION)"
	@echo "Build number: $(BUILD_NUMBER)"
	@echo "Full git version: $(GIT_FULL_VERSION)"

set-version:
	@if [ -z "$(NEW_VERSION)" ]; then \
		echo "Usage: make set-version NEW_VERSION=1.0.0"; \
		exit 1; \
	fi
	@./scripts/set-version.sh $(NEW_VERSION)

sync-version:
	@./scripts/sync-version.sh

validate-build:
	@./scripts/validate-build.sh

docker-build-local:
	@echo "Building local Docker images with version $(VERSION)..."
	docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:$(VERSION) .
	docker build -f Dockerfile.client -t ghcr.io/kenahrens/newboots-client:$(VERSION) .
	@echo "Images built with version $(VERSION)"

check-images:
	@./scripts/check-images.sh
