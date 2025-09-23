# Repository Guidelines

## Project Structure & Module Organization
Application code sits in `src/main/java/com/speedscale/newboots`, with shared models under `src/main/java/com/speedscale/model` and gRPC definitions in `src/main/proto`. Spring configuration, test fixtures, and properties live in `src/main/resources` and `src/test/resources`. Tests mirror the main package under `src/test/java/com/speedscale/newboots`. Operational assets live in `docs/`, `k8s/`, `ecs/`, `examples/`, and reusable automation lands in `scripts/`—extend these scripts instead of adding ad-hoc tooling.

## Architecture Snapshot
The service is a Spring Boot 3.2.3 app on Java 17 exposing REST (port 8080) and gRPC (port 9090). REST controllers such as `NewController` delegate to helper classes (`NasaHelper`, `SpaceXHelper`, `ZipHelper`, `NumberConversionHelper`) and repositories (`InventoryRepository`, `PetRepository`). MongoDB stores inventory data, MySQL stores pet breeds, and initializers populate seed records. gRPC services (`GrpcLocationService`, `AwsAlbGrpcHealthService`) use the protobuf contracts in `src/main/proto`. Proxymock integrations capture external traffic; recordings reside in `proxymock/`.

## Build, Test, and Development Commands
- `mvn clean package`: Build runnable JAR.
- `mvn spring-boot:run`: Launch app locally.
- `mvn test` / `mvn test -Dtest=Class#method`: Run full or targeted tests.
- `mvn checkstyle:check` or `make lint`: Enforce formatting.
- `make dev`: Start MongoDB/MySQL via `docker-compose-databases.yml`.
- `make dev-proxy`: Run app with SOCKS proxy and truststore for proxymock captures.
- `make docker-compose-test`: Boot full stack and execute `scripts/test_endpoints.sh`.
- `make version`, `make set-version NEW_VERSION=...`, `make sync-version`, `make update-k8s-version`: Manage semantic versions and manifests.
- `make docker` or `docker compose up -d`: Build or launch container stack.

## Coding Style & Naming Conventions
Use four-space indentation, braces on new lines, and keep REST controllers thin. Prefer `UpperCamelCase` classes, `lowerCamelCase` members, package-private visibility when feasible, and SLF4J logging over `System.out`. Configuration belongs in `application.yml` or environment variables. Run Checkstyle before committing.

## Testing Guidelines
Adopt JUnit 5 with Spring Boot test slices; unit tests end in `*Test`, integration tests in `*IntegrationTest`. Tests rely on H2 or embedded Mongo where available. Refresh proxymock recordings when external payloads change (`make dev-proxy`). Always execute `mvn test` prior to PR submission and update `scripts/test_endpoints.sh` assertions alongside API edits.

## Commit & Pull Request Guidelines
Commit messages follow short, imperative phrasing (e.g., `add grpc health checks`). PRs should summarize impact, list automated/manual test results, link issues, and call out new environment variables, schema changes, or version bumps. Include sample payloads or screenshots when altering observable responses so reviewers can validate quickly.
