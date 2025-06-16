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

# NASA data
curl http://localhost:8080/nasa

# SpaceX data
curl http://localhost:8080/spacex

# ZIP processing (default)
curl http://localhost:8080/zip

# ZIP processing with specific file
curl http://localhost:8080/zip?filename=jquery
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