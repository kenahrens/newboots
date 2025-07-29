IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest
SOCKS_PROXY ?= -DsocksProxyHost=localhost -DsocksProxyPort=4140
TRUSTSTORE ?= -Djavax.net.ssl.trustStore=$(HOME)/.speedscale/certs/cacerts.jks

.PHONY: test jar docker run lint deploy patch check-k8s-image docker-client docker-server delete clean test-endpoints run-proxy docker-compose-up docker-compose-down

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

# Database-only targets
databases-up:
	docker compose -f docker-compose-databases.yml up -d

databases-down:
	docker compose -f docker-compose-databases.yml down

databases-logs:
	docker compose -f docker-compose-databases.yml logs -f

databases-clean:
	docker compose -f docker-compose-databases.yml down -v

# Local development with databases
dev-setup: databases-up
	@echo "Starting databases..."
	@echo "Waiting for databases to be ready..."
	@sleep 10
	@echo "Databases are ready!"
	@echo "You can now run: mvn spring-boot:run"

dev-clean: databases-down
	@echo "Databases stopped and cleaned up"

# Proxymock recording targets
proxymock-record:
	@echo "Starting proxymock recording with SOCKS proxy on port 4140..."
	@echo "MySQL traffic will be captured through the proxy"
	@echo "Make sure to configure the app to use the proxy settings"
	proxymock record

proxymock-stop:
	@echo "Stopping proxymock recording..."
	pkill -f proxymock

# Development with proxymock recording
dev-with-proxy: databases-up
	@echo "Starting databases..."
	@echo "Starting proxymock recording..."
	proxymock record --out-directory proxymock/recorded-mysql-$(shell date +%Y-%m-%d_%H-%M-%S) --proxy-in-port 4140
	@echo "Databases and proxymock are ready!"
	@echo "Run the app with proxy settings: mvn spring-boot:run -Dspring.profiles.active=proxy"
	@echo "Or set environment variables:"
	@echo "  export JAVA_TOOL_OPTIONS='-DsocksProxyHost=localhost -DsocksProxyPort=4140'"
	@echo "  mvn spring-boot:run"

dev-clean-with-proxy: proxymock-stop-mysql databases-down
	@echo "Proxymock recording stopped and databases cleaned up"

# Run application with proxy
run-with-proxy:
	@echo "Running application with proxymock proxy..."
	@echo "Make sure proxymock is running first with: make proxymock-record-mysql"
	@echo "Setting JAVA_TOOL_OPTIONS for SOCKS proxy and trust store..."
	@export JAVA_TOOL_OPTIONS="-DsocksProxyHost=localhost -DsocksProxyPort=4140 -Djavax.net.ssl.trustStore=$$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit" && \
	echo "JAVA_TOOL_OPTIONS: $$JAVA_TOOL_OPTIONS" && \
	echo "Starting application with proxy profile..." && \
	mvn spring-boot:run -Dspring.profiles.active=proxy

# Complete workflow for proxy recording
proxy-workflow: dev-with-proxy
	@echo "Waiting for proxymock to be ready..."
	@sleep 5
	@echo "Starting application with proxy..."
	@export JAVA_TOOL_OPTIONS="-DsocksProxyHost=localhost -DsocksProxyPort=4140 -Djavax.net.ssl.trustStore=$$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit" && \
	echo "JAVA_TOOL_OPTIONS: $$JAVA_TOOL_OPTIONS" && \
	mvn spring-boot:run -Dspring.profiles.active=proxy

docker-client:
	docker build -f Dockerfile.client -t ghcr.io/kenahrens/newboots-client:latest .
	docker push ghcr.io/kenahrens/newboots-client:latest

docker-server:
	docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:latest .
	docker push ghcr.io/kenahrens/newboots-server:latest

docker: docker-client docker-server
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker push $(IMAGE_NAME):$(TAG)

lint:
	mvn checkstyle:check

deploy:
	kubectl apply -k k8s/overlays/default

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
