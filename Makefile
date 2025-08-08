IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD)
FULL_VERSION ?= $(VERSION).$(BUILD_NUMBER)
SOCKS_PROXY ?= -DsocksProxyHost=localhost -DsocksProxyPort=4140
TRUSTSTORE ?= -Djavax.net.ssl.trustStore=$(HOME)/.speedscale/certs/cacerts.jks

.PHONY: test jar docker run lint deploy patch check-k8s-image docker-client docker-server delete clean test-endpoints run-proxy docker-compose-up docker-compose-down version

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
		-t ghcr.io/kenahrens/newboots-client:$(FULL_VERSION) \
		--push .

docker-server:
	docker buildx build --platform linux/amd64,linux/arm64 \
		-f Dockerfile.server \
		-t ghcr.io/kenahrens/newboots-server:latest \
		-t ghcr.io/kenahrens/newboots-server:$(FULL_VERSION) \
		--push .

# Local single-arch builds (for development)
docker-client-local:
	docker build -f Dockerfile.client -t ghcr.io/kenahrens/newboots-client:$(FULL_VERSION)-local .

docker-server-local:
	docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:$(FULL_VERSION)-local .

docker: docker-client docker-server
	@echo "Built and pushed multi-arch images with version $(FULL_VERSION)"

docker-local: docker-client-local docker-server-local
	@echo "Built local images with version $(FULL_VERSION)-local"

lint:
	mvn checkstyle:check

deploy:
	kubectl apply -k k8s/overlays/default

deploy-version:
	@echo "Deploying version $(FULL_VERSION)"
	@sed 's|ghcr.io/kenahrens/newboots-server:latest|ghcr.io/kenahrens/newboots-server:$(FULL_VERSION)|g' k8s/base/deploy.yaml | kubectl apply -f -

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
	@echo "Base version: $(VERSION)"
	@echo "Build number: $(BUILD_NUMBER)"
	@echo "Full version: $(FULL_VERSION)"
