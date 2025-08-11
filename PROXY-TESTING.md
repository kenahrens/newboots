# Proxy Testing and Traffic Capture Guide

## Overview
This document covers how to capture and record HTTP traffic from the Spring Boot newboots application using proxymock. It includes methods for:
- SOCKS proxy recording (NASA/SpaceX APIs using Google HTTP client)
- HTTP(S) proxy recording (Hugging Face API using Reactor Netty WebClient)
- Quick capture scripts for common scenarios

**Key Findings**
- SOCKS baseline: `-DsocksProxyHost=localhost -DsocksProxyPort=4140` plus truststore captures NASA and SpaceX.
- Reactor Netty: Does not honor SOCKS by default; requires HTTP(S) proxy configuration.
- Working approach: Configure WebClient to use `HttpClient.create().proxyWithSystemProperties()` and run the app with `-Dhttp.proxyHost/Port` and `-Dhttps.proxyHost/Port` pointing to proxymock (4140).

## Prerequisites
- proxymock installed and on PATH
- Java truststore for proxymock TLS interception: `~/.speedscale/certs/cacerts.jks` (password `changeit`)
- App runs on `:8080` (default in `application.properties`)

## Quick Start Scripts

### Capture Reactor Netty Traffic
The `capture-reactor-netty.sh` script provides the simplest way to capture Reactor Netty WebClient traffic:

```bash
./capture-reactor-netty.sh
```

This script automatically:
1. Starts proxymock recording with HTTP proxy
2. Runs the application with proper proxy settings
3. Makes test API calls to capture traffic
4. Saves recordings to `proxymock/recorded-{timestamp}-reactor-netty/`

## Manual Recording Methods

### Method 1: SOCKS Recording (NASA/SpaceX)
Start proxymock in a terminal:
```bash
proxymock record --out proxymock/recorded-$(date +%Y-%m-%d_%H-%M-%S)-socks --app-port 8080
```

In another terminal, run the app with SOCKS + truststore:
```bash
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-DsocksProxyHost=localhost -DsocksProxyPort=4140 -Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit"
```

Exercise endpoints:
```bash
curl http://localhost:8080/nasa
curl http://localhost:8080/spacex
```

### Method 2: HTTP(S) Proxy Recording (Reactor Netty/Hugging Face)

#### Using proxymock command-line tool
Start proxymock:
```bash
proxymock record --out proxymock/recorded-$(date +%Y-%m-%d_%H-%M-%S)-reactor-http --app-port 8080
```

Run the app with HTTP(S) proxy + truststore:
```bash
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dhttp.proxyHost=localhost -Dhttp.proxyPort=4140 -Dhttps.proxyHost=localhost -Dhttps.proxyPort=4140 -Djavax.net.ssl.trustStore=$HOME/.speedscale/certs/cacerts.jks -Djavax.net.ssl.trustStorePassword=changeit"
```

#### Using proxymock start-recording-traffic
Alternative approach using the newer proxymock API:
```bash
proxymock start-recording-traffic \
  --app-port 8080 \
  --proxy-in-port 4143 \
  --out-directory proxymock/recorded-reactor-netty
```

Then run the app with proxy environment variables:
```bash
HTTP_PROXY=http://localhost:4143 \
HTTPS_PROXY=http://localhost:4143 \
mvn spring-boot:run
```

Exercise endpoint:
```bash
curl http://localhost:8080/models/openai
```

Stop recording:
```bash
proxymock stop-recording-traffic
```

## Code Configuration

### Reactor Netty WebClient Configuration
The `ReactiveApiHelper.java` has been configured to honor system proxy properties:

```java
HttpClient httpClient = HttpClient.create()
    .proxyWithSystemProperties();

this.webClient = WebClient.builder()
    .clientConnector(new ReactorClientHttpConnector(httpClient))
    .build();
```

For manual proxy configuration, you can use:
```java
HttpClient httpClient = HttpClient.create()
    .proxy(proxy -> proxy
        .type(ProxyProvider.Proxy.HTTP)
        .host("localhost")
        .port(4143));
```

### Environment Overrides
- `HF_API_BASE`: Override Hugging Face API base URL (default: `https://huggingface.co`)
- `HF_API_HOST`: Override Hugging Face host header (default: `huggingface.co`)

## Helper Scripts
Located in the `scripts/` directory:
- `record-baseline-socks.sh`: Automates proxymock + app + NASA/SpaceX checks
- `record-reactor-netty-http-proxy.sh`: Automates proxymock + app + Hugging Face check via HTTP(S) proxy
- `setup-reverse-proxy-capture.sh`: Sets up reverse proxy capture (alternative method)

## Verification
After recording, check the `proxymock/` directory for your recordings:
- SOCKS recordings: Look for `api.nasa.gov/` and `api.spacexdata.com/` subdirectories
- HTTP proxy recordings: Look for `huggingface.co/` subdirectory
- Files are saved in proxymock's RRPair format (.md or .json files)

## What Gets Captured
The recordings include:
- Request method, URL, headers, and body
- Response status, headers, and body
- Timing information
- TLS handshake details (when using truststore)

## Cleanup
- Stop the Spring app: `Ctrl+C`
- Stop proxymock: `Ctrl+C` or `make proxymock-stop`
- Recording directories are timestamped and won't be overwritten

## Troubleshooting

### No recordings appearing
- Ensure proxymock is running before starting the application
- Verify proxy settings are correctly passed to the JVM
- Check that the truststore path is correct for HTTPS interception

### Reactor Netty not recording
- Confirm `proxyWithSystemProperties()` is configured in WebClient
- Verify HTTP(S) proxy properties are set (not just SOCKS)
- Check application logs for proxy connection errors

### Certificate errors
- Ensure the proxymock truststore is properly configured
- Path: `~/.speedscale/certs/cacerts.jks`
- Password: `changeit`

## Notes
- Sensitive data in API responses will be captured, handle recordings appropriately
- Recordings are stored locally and not automatically uploaded
- Each recording session creates a new timestamped directory