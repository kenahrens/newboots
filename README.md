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
- `GET /pets/types?type={type}` - Gets pet breeds based on the provided pet type (e.g., dog, cat, bird)


## Prerequisites

- **Java 17** or higher
- **Maven 3.6** or higher
- **MongoDB 6.0** or higher (for inventory data)
- **MySQL 8.0** or higher (for pet breeds data)
- **Docker** (optional, for containerized deployment)
- **Kubernetes** (optional, for k8s deployment)

## Dependencies

### Core Dependencies
- **Spring Boot 3.2.3** - Main application framework
- **Spring Web** - REST API support
- **Spring Actuator** - Health monitoring and metrics
- **Spring Data JPA** - Database abstraction layer
- **Spring Data MongoDB** - MongoDB integration

### Database Dependencies
- **MySQL Connector/J 8.0.33** - MySQL database driver
- **H2 Database** - In-memory database for testing

### HTTP Client Dependencies
- **Google HTTP Client 1.43.3** - For external API calls (NASA, SpaceX)
- **Apache HTTP Client 5.3.1** - For ZIP file operations

### Utility Dependencies
- **Apache Commons IO 2.15.1** - File operations
- **Jackson** - JSON processing
- **SLF4J** - Logging framework

### SOAP API Dependencies
- **javax.xml.soap-api 1.4.0** - SOAP API support
- **saaj-impl 1.5.3** - SOAP implementation


### Test Dependencies
- **Spring Boot Test** - Testing framework
- **JUnit 5** - Unit testing
- **Mockito** - Mocking framework

## Building and Running

### Local Development Setup

1. **Start MongoDB:**
   ```bash
   # Using Docker
   docker run -d --name mongo -p 27017:27017 mongo:6.0
   
   # Or using MongoDB locally
   mongod --dbpath /path/to/data/db
   ```

2. **Start MySQL:**
   ```bash
   # Using Docker
   docker run -d --name mysql -p 3306:3306 \
     -e MYSQL_ROOT_PASSWORD=password \
     -e MYSQL_DATABASE=newboots \
     -e MYSQL_USER=newboots \
     -e MYSQL_PASSWORD=newboots \
     mysql:8.0
   
   # Or using MySQL locally
   mysql -u root -p
   CREATE DATABASE newboots;
   CREATE USER 'newboots'@'%' IDENTIFIED BY 'newboots';
   GRANT ALL PRIVILEGES ON newboots.* TO 'newboots'@'%';
   FLUSH PRIVILEGES;
   ```

3. **Build the application:**
   ```bash
   mvn clean package
   ```

4. **Run the application:**
   ```bash
   mvn spring-boot:run
   ```

5. **Or run the JAR file:**
   ```bash
   java -jar target/newboots-0.0.1-SNAPSHOT.jar
   ```

### Using Docker Compose (Recommended)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  mongo:
    image: mongo:6.0
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_DATABASE: newboots
    volumes:
      - mongo_data:/data/db

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: newboots
      MYSQL_USER: newboots
      MYSQL_PASSWORD: newboots
    volumes:
      - mysql_data:/var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password

  newboots:
    build: .
    ports:
      - "8080:8080"
    environment:
      MONGODB_URI: mongodb://mongo:27017/newboots
      MYSQL_URL: jdbc:mysql://mysql:3306/newboots?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
      MYSQL_USERNAME: newboots
      MYSQL_PASSWORD: newboots
    depends_on:
      - mongo
      - mysql

volumes:
  mongo_data:
  mysql_data:
```

Then run:
```bash
docker-compose up -d
```

### Local Development with Docker Databases (Recommended for Development)

For local development, you can run just the databases in Docker and the application locally:

1. **Start only the databases:**
   ```bash
   make databases-up
   # or manually:
   docker-compose -f docker-compose-databases.yml up -d
   ```

2. **Run the application locally:**
   ```bash
   mvn spring-boot:run
   ```

3. **Stop the databases when done:**
   ```bash
   make databases-down
   # or manually:
   docker-compose -f docker-compose-databases.yml down
   ```

**Available Makefile targets for database management:**
- `make databases-up` - Start MongoDB and MySQL
- `make databases-down` - Stop the databases
- `make databases-logs` - View database logs
- `make databases-clean` - Stop and remove database volumes
- `make dev` - Start databases and show ready message
- `make dev-clean` - Stop and clean up databases

This approach gives you:
- Fast application startup (no Docker build needed)
- Easy debugging and hot reloading
- Persistent database data
- Full control over the application environment

### Proxymock Recording for MySQL Traffic

For capturing MySQL traffic with proxymock, you can use the SOCKS proxy setup:

#### Prerequisites

**Add entries to your `/etc/hosts` file:**
```bash
# Add these lines to /etc/hosts (requires sudo)
YOUR_IP_ADDRESS mongo
```

#### Step-by-Step Proxymock Setup

1. **Start proxymock recording in one terminal window:**
   ```bash
   make proxymock-record
   ```

2. **In another terminal window, run the development environment:**
   ```bash
   make dev-proxy
   ```

3. **Test the application to generate database traffic:**
   ```bash
   # Test MySQL endpoint (pets)
   curl http://localhost:8080/pets/types
   curl http://localhost:8080/pets/types?type=dog
   ```

4. **View traffic in proxymock directory**

5. **Clean up when done:**
   ```bash
   make dev-proxy-clean
   ```

#### Alternative: Complete Workflow

1. **Complete workflow (recommended):**
   ```bash
   make dev-proxy
   ```

2. **Or start components separately:**
   ```bash
   make databases-up
   make proxymock-record
   # Then run the app manually with proxy settings
   ```

3. **Clean up when done:**
   ```bash
   make dev-proxy-clean
   ```

**Available proxymock targets:**
- `make proxymock-record` - Start proxymock recording with SOCKS proxy on port 4140
- `make proxymock-stop` - Stop proxymock recording (uses pkill)
- `make dev-proxy` - Complete workflow (databases + proxymock + app)
- `make dev-proxy-clean` - Stop proxymock and clean up databases

**How it works:**
- Proxymock creates a SOCKS proxy on port 4140
- The application uses hostnames `mongodb` and `mysql` (Docker network aliases)
- Java networking is configured to use the SOCKS proxy via `JAVA_TOOL_OPTIONS`
- Trust store is configured from `~/.speedscale/certs/cacerts.jks`
- All database traffic is captured through the proxy

**Java Options for Proxy:**
```bash
-DsocksProxyHost=localhost
-DsocksProxyPort=4140
-Djavax.net.ssl.trustStore=~/.speedscale/certs/cacerts.jks
-Djavax.net.ssl.trustStorePassword=changeit
```

**Database hostnames:**
- MongoDB: `mongodb:27017`
- MySQL: `mysql:3306`

These hostnames are resolved through the Docker network and routed through the SOCKS proxy for traffic capture.

## Versioning and Multi-Architecture Support

This project supports multi-architecture Docker builds and semantic versioning. See [VERSIONING.md](./VERSIONING.md) for complete details.

### Quick Version Commands
```bash
# Check current version
make version

# Build multi-arch images (requires push access)
make docker

# Build local development images
make docker-local
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

# Pet types (all breeds)
curl http://localhost:8080/pets/types

# Pet types (search by type)
curl http://localhost:8080/pets/types?type=dog

# Inventory search (MongoDB)
curl http://localhost:8080/inventory/search?key=item&value=journal
curl http://localhost:8080/inventory/search?key=qty&value=25
curl http://localhost:8080/inventory/search?key=status&value=A
```


## Configuration

The application uses the following default configuration:
- Port: 8080
- Logging level: INFO
- Actuator endpoints: health, info

Configuration can be modified in `src/main/resources/application.properties`.

## MongoDB Requirement

This service requires a MongoDB instance. By default, it connects to `mongodb://mongo:27017/newboots`.

To override the connection string, set the `MONGODB_URI` environment variable:

```bash
export MONGODB_URI="mongodb://localhost:27017/newboots"
```

The application will automatically initialize the `inventory` collection with sample data if it is empty.

## MySQL Requirement

This service also requires a MySQL instance. By default, it connects to `jdbc:mysql://localhost:3306/newboots`.

To override the connection settings, set the following environment variables:

```bash
export MYSQL_URL="jdbc:mysql://localhost:3306/newboots?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
export MYSQL_USERNAME="your_username"
export MYSQL_PASSWORD="your_password"
```

The application will automatically initialize the `pets` table with sample data if it is empty. 