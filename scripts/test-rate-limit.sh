#!/bin/bash

echo "Testing NASA endpoint rate limiting..."
echo "Making first request (should succeed):"
curl -s http://localhost:8080/nasa | jq '.' || echo "Response: $(curl -s http://localhost:8080/nasa)"

echo -e "\n\nMaking second request immediately (should be rate limited):"
curl -s http://localhost:8080/nasa | jq '.' || echo "Response: $(curl -s http://localhost:8080/nasa)"

echo -e "\n\nNote: Next successful request will be allowed after 10 minutes."