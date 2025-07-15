# Newboots - Spring Boot Microservice

A Spring Boot microservice application built with Spring Boot 3.2.3 and Java 17.

## Features

- **NASA API Integration**: Fetches data from NASA's APOD (Astronomy Picture of the Day) API
- **SpaceX API Integration**: Retrieves latest SpaceX launch information
- **ZIP File Processing**: Downloads and processes ZIP files from various sources
- **Health Monitoring**: Built-in health check endpoints
- **RESTful API**: Clean REST endpoints for all functionality

## Endpoints

- `GET /` - Home endpoint returning basic application info
- `GET /healthz` - Health check endpoint
- `GET /greeting?name={name}` - Greeting endpoint with customizable name
- `GET /nasa` - Fetches NASA APOD data
- `GET /spacex` - Fetches latest SpaceX launch data
- `GET /zip?filename={filename}` - Processes ZIP files (optional filename parameter)
- `POST /location` - Accepts and returns location data
- `GET /number-to-words?number={number}` - Converts a number to words using a SOAP API
- `GET /inventory/search?key={key}&value={value}` - Searches inventory for documents where the given key equals the given value

### gRPC (port 9090)
- `LocationService/EchoLocation(Location) -> Location`
- `Health/Check(HealthCheckRequest) -> HealthCheckResponse`
- `Health/AWSALBHealthCheck(HealthCheckRequest) -> HealthCheckResponse`

## Prerequisites

- Java 17 or higher
- Maven 3.6 or higher

## Building and Running

1. **Build the application:**
   ```bash
   mvn clean package
   ```

2. **Run the application:**
   ```bash
   mvn spring-boot:run
   ```

3. **Or run the JAR file:**
   ```bash
   java -jar target/newboots-0.0.1-SNAPSHOT.jar
   ```

## Testing the Endpoints

Once the application is running on port 8080, you can test the endpoints:

```bash
# Home endpoint
curl http://localhost:8080/

# Health check
curl http://localhost:8080/healthz

# Greeting endpoint
curl http://localhost:8080/greeting?name=World

# NASA data
curl http://localhost:8080/nasa

# SpaceX data
curl http://localhost:8080/spacex

# ZIP processing (default)
curl http://localhost:8080/zip

# ZIP processing with specific file
curl http://localhost:8080/zip?filename=jquery

# POST location data
curl -X POST -H "Content-Type: application/json" -d '{"latitude": 1.0, "longitude": 2.0, "macAddress": "aa:bb:cc:dd:ee:ff", "ipv4": "127.0.0.1"}' http://localhost:8080/location

# Number to words
curl http://localhost:8080/number-to-words?number=123
```

### Testing the gRPC Endpoints

You can use a gRPC client such as `grpcurl` to test the gRPC endpoints.

```bash
# EchoLocation
grpcurl -d '{"latitude": 1.0, "longitude": 2.0, "macAddress": "aa:bb:cc:dd:ee:ff", "ipv4": "127.0.0.1"}' -plaintext localhost:9090 LocationService/EchoLocation

# HealthCheck
grpcurl -plaintext localhost:9090 Health/Check

# AWSALBHealthCheck
grpcurl -plaintext localhost:9090 Health/AWSALBHealthCheck
```

## Configuration

The application uses the following default configuration:
- Port: 8080
- Logging level: INFO
- Actuator endpoints: health, info

Configuration can be modified in `src/main/resources/application.properties`.

## Dependencies

- Spring Boot 3.2.3
- Spring Web
- Spring Actuator
- Google HTTP Client
- Apache HTTP Client 5
- Apache Commons IO
- Jackson for JSON processing 

## MongoDB Requirement

This service requires a MongoDB instance. By default, it connects to `mongodb://mongo:27017/newboots`.

To override the connection string, set the `MONGODB_URI` environment variable:

```bash
export MONGODB_URI="mongodb://localhost:27017/newboots"
```

The application will automatically initialize the `inventory` collection with sample data if it is empty. 