# Project Background and Summary

## Overview
This project is a Java 17 microservice built with Spring Boot 3.2.3. It exposes both HTTP (REST) and gRPC endpoints. The codebase is organized with clear separation between controllers, helpers, and service implementations. The project uses Maven for build and dependency management, and includes Docker and Kubernetes deployment configurations.

## Rules
* Check your own work through unit tests, integration tests
* When something is done move that item to a DONE list in this file
* **Always run `mvn checkstyle:check` before committing and pushing code to ensure there are no Checkstyle violations.**


## Architecture
- **Spring Boot**: Main application entry in `NewbootsApplication.java`.
- **HTTP Endpoints**: Defined in `NewController.java` (see below for details).
- **gRPC Endpoints**: Implemented in `GrpcLocationService.java` and `AwsAlbGrpcHealthService.java`, using classes generated from `src/main/proto/location.proto`.
- **Helpers**: Utility classes for NASA, SpaceX, ZIP, and number conversion logic.
- **Tests**: JUnit-based tests for core logic and integration, including gRPC and REST endpoints.

## Endpoints
### HTTP (port 8080)
- `GET /` — Returns `{ "spring": "is here" }`
- `GET /healthz` — Returns `{ "health": "health" }`
- `GET /greeting?name=...` — Returns a greeting message
- `GET /nasa` — Calls NASA API (via helper)
- `GET /spacex` — Calls SpaceX API (via helper)
- `POST /location` — Echoes a Location object
- `GET /zip?filename=...` — Processes ZIP files (via helper)
- `GET /number-to-words?number=...` — Converts a number to words

### gRPC (port 9090)
- `LocationService/EchoLocation(Location) -> Location`
- `Health/Check(HealthCheckRequest) -> HealthCheckResponse`
- `Health/AWSALBHealthCheck(HealthCheckRequest) -> HealthCheckResponse`

## Build & Run Instructions
- **Build JAR**: `make jar` (runs `mvn clean package`)
- **Run Locally**: `make run` (runs `mvn spring-boot:run`)
- **Docker Images**: `make docker` (Note: Docker images are built and pushed by the GitHub Actions pipeline, not locally)
- **Kubernetes Deploy**: `make deploy`
- **Infrastructure as Code**: We use [Tofu](https://opentofu.org/) (not Terraform) for managing infrastructure in the `ecs/terraform` directory. Use `tofu plan` and `tofu apply` instead of Terraform commands.
- **AWS CLI**: When using the AWS CLI, you must set `AWS_PAGER=""` and use the `--profile demo` flag.

## Script Execution Order
1. **`make lint`**: Run `mvn checkstyle:check` to ensure code quality.
2. **`make test`**: Run unit and integration tests.
3. **`make jar`**: Build the application JAR.
4. **`make docker`**: Build and push Docker images.
5. **`tofu apply`**: Deploy infrastructure changes using Tofu.
6. **`./scripts/validate_deployment.sh`**: Verify that the ECS services are deployed and running correctly.
7. **`./scripts/test_endpoints.sh`**: Run end-to-end tests against the deployed application and validate Speedscale integration.
8. **`./scripts/fix_trailing_newlines.sh`**: (Optional) Fix trailing newlines in files.

## ECS Deployment Notes
* In the ECS deployment, only the gRPC port (9090) is exposed. HTTP endpoints on port 8080 are not accessible from the ALB. Therefore, health checks must use the gRPC health endpoints.

## Validation for ECS
* Check that the goproxy LOG_LEVEL is set to debug
* Make sure that the latest version is running, force restart the ECS if necessary
* Send some test transactions
* After waiting 2 minutes, check if the data has arrived in speedscale

## DONE
* Clarify script execution order in `plan.md`
* Fix the `ClassNotFoundException: HealthCheckRequest` error during tests (workaround: build and run JAR with tests skipped)
* Ensure the JAR is built and can be run with `java -jar ...`
* Create the test script in a dedicated scripts directory and ensure it can be called from the Makefile
* Validate all endpoints with the provided test script
* Ensure no linter errors (`make lint`)
* Review and improve test coverage for all endpoints
* Review Dockerfiles for correctness (updated Dockerfile.server to expose both 8080 and 9090)
* Review Kubernetes manifests for correctness (added gRPC port 9090 to Deployment and Service)
* Review ECS deployment (Terraform) for correctness
* Investigate and fix the unimplemented gRPC Health/Check endpoint (now implemented and passing tests)
