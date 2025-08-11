# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Basic Commands
- **Build**: `mvn clean package`
- **Run tests**: `mvn test`
- **Run application**: `mvn spring-boot:run`
- **Lint code**: `mvn checkstyle:check`
- **Run single test**: `mvn test -Dtest=TestClassName#methodName`

### Database Setup
- **Start databases**: `make databases-up` or `docker compose -f docker-compose-databases.yml up -d`
- **Stop databases**: `make databases-down`
- **Clean databases**: `make databases-clean`

### Local Development
- **Start dev environment**: `make dev` (starts MongoDB and MySQL in Docker)
- **Run with proxymock**: `make dev-proxy` (includes SOCKS proxy for traffic capture)

### Version Management
- **Check current version**: `make version`
- **Set new version**: `make set-version NEW_VERSION=1.0.0`
- **Sync version to pom.xml**: `make sync-version`
- **Update K8s manifests**: `make update-k8s-version`

### Docker Operations
- **Build all images**: `make docker`
- **Run with Docker Compose**: `docker compose up -d`

## Architecture Overview

This is a Spring Boot 3.2.3 microservice with Java 17 that demonstrates various integration patterns:

### Core Components
1. **HTTP REST API** (port 8080)
   - Spring Web MVC controllers in `com.speedscale.newboots`
   - Main controller: `NewController.java`
   - Endpoints for NASA, SpaceX, ZIP processing, inventory, and pet data

2. **gRPC Services** (port 9090)
   - Protocol buffer definitions in `src/main/proto/`
   - Service implementations: `GrpcLocationService`, `AwsAlbGrpcHealthService`
   - Uses grpc-spring-boot-starter for auto-configuration

3. **Database Integration**
   - **MongoDB**: For inventory data (`InventoryRepository`)
   - **MySQL**: For pet breeds data (`PetRepository`)
   - Both use Spring Data with automatic schema/collection initialization

4. **External API Integration**
   - `NasaHelper`: Fetches NASA APOD data
   - `SpaceXHelper`: Retrieves SpaceX launch information
   - `ZipHelper`: Downloads and processes ZIP files
   - `NumberConversionHelper`: SOAP API client for number-to-words conversion

### Key Design Patterns
- **Repository Pattern**: Spring Data repositories for database access
- **Helper Classes**: Separate classes for external API integrations
- **Data Initializers**: `InventoryInitializer` and `PetInitializer` populate initial data
- **Configuration**: Environment-based configuration via Spring properties

### Proxymock Integration
The project includes comprehensive proxymock setup for recording and mocking API traffic:
- SOCKS proxy configuration for capturing database traffic
- Custom hostnames for better traffic grouping
- Recording directories in `proxymock/` contain captured RRPair files
- Use `make dev-proxy` for automatic setup with proper Java options

### Testing Approach
- JUnit 5 with Spring Boot Test
- Integration tests for endpoints and external APIs
- H2 in-memory database for test isolation
- Test properties in `src/test/resources/application.properties`