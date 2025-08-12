# Reverse Proxy Recording with Proxymock

## Overview
This guide shows how to capture HTTP traffic from the Spring Boot newboots application using proxymock's reverse proxy feature. This is particularly useful for recording traffic from reactive HTTP clients like Reactor Netty WebClient that don't easily work with traditional HTTP proxies.

> **⚠️ Note on TLS/HTTPS Traffic**: Currently, proxymock's reverse proxy feature works reliably with non-encrypted HTTP traffic. Support for TLS/HTTPS reverse proxy recording is still being researched due to issues with how some services (like CloudFront) handle requests with explicit port numbers in the URL.

## The Reactor Netty Challenge
Reactor Netty WebClient, used by external API integrations in this application, presents unique challenges for traffic recording:

- **Proxy resistance**: WebClient doesn't automatically respect system proxy settings
- **Code changes required**: Using traditional HTTP proxies requires modifying the WebClient configuration with `proxyWithSystemProperties()` or custom proxy settings
- **Connection pooling**: Reactor Netty's connection pooling can interfere with proxy routing

**Solution**: Proxymock's reverse proxy feature eliminates these issues by intercepting traffic at the network level without requiring any code changes.

## Prerequisites
- proxymock installed and on PATH
- Application runs on port 8080 (default)

## Manual Setup

### 1. Start Proxymock with Reverse Proxy
```bash
# Start recording with reverse proxy for Numbers API
proxymock record \
  --reverse-proxy 65080=numbersapi.com:80 \
  --app-port 8080 \
  --out proxymock/recorded-$(date +%Y-%m-%d_%H-%M-%S)
```

This configures proxymock to:
- Listen on port 65080 locally
- Forward all traffic to numbersapi.com:80
- Record all request/response pairs

### 2. Run Application with Environment Override
```bash
# Point the app to use our reverse proxy instead of the real API
NUMBERS_API_BASE=http://localhost:65080 \
mvn spring-boot:run
```

The `NUMBERS_API_BASE` environment variable redirects the WebClient to connect to the proxymock reverse proxy instead of the real Numbers API.

### 3. Exercise the API
```bash
# Make a call that triggers the Reactor Netty WebClient
curl http://localhost:8080/numberfact
```

### 4. View Results
Check the recording directory for captured traffic:
```bash
ls proxymock/recorded-*/localhost/
```

## How It Works

1. **Application Configuration**: The `ReactiveApiHelper.java` reads the `NUMBERS_API_BASE` environment variable:
   ```java
   private static final String NUMBERS_API_BASE =
       System.getenv("NUMBERS_API_BASE") != null
           ? System.getenv("NUMBERS_API_BASE")
           : "http://numbersapi.com";
   ```

2. **Traffic Flow**:
   - App makes request to `http://localhost:65080/random/trivia`
   - Proxymock intercepts the request
   - Proxymock forwards to `http://numbersapi.com:80/random/trivia`
   - Response flows back through proxymock to the app
   - All traffic is recorded as RRPair files

3. **No Code Changes**: The WebClient continues to work normally, unaware it's connecting to a proxy.

## Example Recording
After running the recording, you'll see files like this in `proxymock/recorded-{timestamp}/localhost/`:

```
2025-08-12_12-18-35.383552Z.md
```

Content of a typical RRPair file shows the complete request/response pair:
```markdown
### REQUEST ###
GET http://localhost:65080/random/trivia HTTP/1.1
Accept: */*
Host: localhost:65080
User-Agent: ReactorNetty/1.1.16

### RESPONSE (MOCK) ###
Content-Type: text/plain; charset=utf-8
Date: Tue, 12 Aug 2025 12:01:46 GMT
Server: nginx/1.4.6 (Ubuntu)
X-Numbers-Api-Number: 158
X-Numbers-Api-Type: trivia

158 is the number of international goals scored by Mia Hamm for the USA women's team, an all-time record for either sex in soccer.

### METADATA ###
direction: OUT
duration: 39ms
tags: captureMode=proxy, proxyProtocol=tcp:http, reverseProxyHost=localhost
```

The recording captures:
- **Complete HTTP request** including headers, query parameters, and body
- **Full response** with status, headers, and body content  
- **Metadata** showing it was captured via reverse proxy with 39ms duration
- **User-Agent: ReactorNetty/1.1.16** confirming WebClient traffic was recorded

## Verification Steps
1. **Check recording directory**: `ls proxymock/recorded-*/`
2. **Verify host capture**: Look for `localhost/` subdirectory
3. **Review RRPair files**: Open `.md` files to see captured requests/responses
4. **Test completeness**: Ensure all API calls made during testing are recorded

## Environment Variables
- `NUMBERS_API_BASE`: Override base URL for Numbers API (default: `http://numbersapi.com`)
  - For recording: Use `http://localhost:65080` to connect to reverse proxy

## Troubleshooting

### No recordings appear
- Verify proxymock is running before starting the application
- Check that `NUMBERS_API_BASE` environment variable is set to `http://localhost:65080`
- Confirm the reverse proxy port (65080) is listening: `lsof -i :65080`

### Application errors
- Verify reverse proxy port (65080) is available and not in use by other services
- Check proxymock logs for connection errors
- Ensure application is using the correct `NUMBERS_API_BASE=http://localhost:65080` value

## Cleanup
- Stop the application: `Ctrl+C`
- Stop proxymock: `Ctrl+C`
- Recording directories are timestamped and won't be overwritten

## Notes
- This approach works with any HTTP client library, not just Reactor Netty
- Sensitive data in API responses will be captured - handle recordings appropriately  
- Recordings are stored locally and not automatically uploaded
- Each recording session creates a new timestamped directory