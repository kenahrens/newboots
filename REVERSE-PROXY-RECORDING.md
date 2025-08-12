# Reverse Proxy Recording with Proxymock

## Overview
This guide shows how to capture HTTP traffic from the Spring Boot newboots application using proxymock's reverse proxy feature. This is particularly useful for recording traffic from reactive HTTP clients like Reactor Netty WebClient that don't easily work with traditional HTTP proxies.

## The Reactor Netty Challenge
Reactor Netty WebClient, used by the Hugging Face API integration in this application, presents unique challenges for traffic recording:

- **Proxy resistance**: WebClient doesn't automatically respect system proxy settings
- **Code changes required**: Using traditional HTTP proxies requires modifying the WebClient configuration with `proxyWithSystemProperties()` or custom proxy settings
- **Connection pooling**: Reactor Netty's connection pooling can interfere with proxy routing

**Solution**: Proxymock's reverse proxy feature eliminates these issues by intercepting traffic at the network level without requiring any code changes.

## Prerequisites
- proxymock installed and on PATH
- Java truststore for proxymock TLS interception: `~/.speedscale/certs/cacerts.jks` (password `changeit`)
- Application runs on port 8080 (default)

## Quick Start
Use the automated script to record Reactor Netty traffic:

```bash
./scripts/record-reactor-netty.sh
```

This script automatically handles the setup and captures traffic to `proxymock/recorded-{timestamp}/`.

## Manual Setup

### 1. Start Proxymock with Reverse Proxy
```bash
# Start recording with reverse proxy for Hugging Face API
proxymock record \
  --reverse-proxy 65443=huggingface.co:443 \
  --app-port 8080 \
  --out proxymock/recorded-$(date +%Y-%m-%d_%H-%M-%S)
```

This configures proxymock to:
- Listen on port 65443 locally
- Forward all traffic to huggingface.co:443
- Record all request/response pairs

### 2. Run Application with Environment Override
```bash
# Point the app to use our reverse proxy instead of the real API
HF_API_BASE=http://localhost:65443 \
mvn spring-boot:run
```

The `HF_API_BASE` environment variable redirects the WebClient to connect to the proxymock reverse proxy instead of the real Hugging Face API. Note we use `http://` instead of `https://` to avoid SSL certificate complications - proxymock handles the HTTPS connection to the target server.

### 3. Exercise the API
```bash
# Make a call that triggers the Reactor Netty WebClient
curl http://localhost:8080/models/openai
```

### 4. View Results
Check the recording directory for captured traffic:
```bash
ls proxymock/recorded-*/huggingface.co/
```

## How It Works

1. **Application Configuration**: The `ReactiveApiHelper.java` reads the `HF_API_BASE` environment variable:
   ```java
   private static final String HF_API_BASE =
       System.getenv("HF_API_BASE") != null
           ? System.getenv("HF_API_BASE")
           : "https://huggingface.co";
   ```

2. **Traffic Flow**:
   - App makes request to `http://localhost:65443/api/models`
   - Proxymock intercepts the request
   - Proxymock forwards to `https://huggingface.co:443/api/models`
   - Response flows back through proxymock to the app
   - All traffic is recorded as RRPair files

3. **No Code Changes**: The WebClient continues to work normally, unaware it's connecting to a proxy.

## Example Recording
After running the recording, you'll see files like this in `proxymock/recorded-{timestamp}/huggingface.co/`:

```
2025-08-12_01-37-18.830172Z.md
```

Content of a typical RRPair file shows the complete request/response pair:
```markdown
### REQUEST ###
GET http://huggingface.co:443/api/models?author=openai&limit=10 HTTP/1.1
Accept: */*
Host: huggingface.co
User-Agent: ReactorNetty/1.1.16

### RESPONSE (MOCK) ###
Content-Type: application/json
Date: Tue, 12 Aug 2025 01:37:18 GMT
Server: CloudFront

[Response body content...]

### METADATA ###
direction: OUT
duration: 23ms
tags: captureMode=proxy, proxyProtocol=tcp:http, reverseProxyHost=localhost
```

The recording captures:
- **Complete HTTP request** including headers, query parameters, and body
- **Full response** with status, headers, and body content  
- **Metadata** showing it was captured via reverse proxy with 23ms duration
- **User-Agent: ReactorNetty/1.1.16** confirming WebClient traffic was recorded

## Verification Steps
1. **Check recording directory**: `ls proxymock/recorded-*/`
2. **Verify host capture**: Look for `huggingface.co/` subdirectory
3. **Review RRPair files**: Open `.md` files to see captured requests/responses
4. **Test completeness**: Ensure all API calls made during testing are recorded

## Environment Variables
- `HF_API_BASE`: Override base URL for Hugging Face API (default: `https://huggingface.co`)
  - For recording: Use `http://localhost:65443` to connect to reverse proxy
- `HF_API_HOST`: Override host header if needed (default: `huggingface.co`)

## Troubleshooting

### No recordings appear
- Verify proxymock is running before starting the application
- Check that `HF_API_BASE` environment variable is set to `http://localhost:65443`
- Confirm the reverse proxy port (65443) is listening: `lsof -i :65443`

### Application errors
- Verify reverse proxy port (65443) is available and not in use by other services
- Check proxymock logs for connection errors
- Ensure application is using the correct `HF_API_BASE=http://localhost:65443` value
- If you see SSL/TLS errors, make sure you're using `http://` not `https://` for the localhost connection

## Cleanup
- Stop the application: `Ctrl+C`
- Stop proxymock: `Ctrl+C`
- Recording directories are timestamped and won't be overwritten

## Notes
- This approach works with any HTTP client library, not just Reactor Netty
- Sensitive data in API responses will be captured - handle recordings appropriately  
- Recordings are stored locally and not automatically uploaded
- Each recording session creates a new timestamped directory