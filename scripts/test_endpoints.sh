#!/bin/bash
set -e

# HTTP endpoints (8080)
echo "Testing HTTP endpoints..."
curl -s http://localhost:8080/ | grep 'spring'
curl -s http://localhost:8080/healthz | grep 'health'
curl -s "http://localhost:8080/greeting?name=Test" | grep 'Hello'
curl -s http://localhost:8080/nasa
curl -s http://localhost:8080/spacex
curl -s -X POST http://localhost:8080/location -H 'Content-Type: application/json' -d '{"locationID":"1","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}'
curl -s http://localhost:8080/zip
curl -s "http://localhost:8080/number-to-words?number=123" | grep 'one hundred'

echo "Testing gRPC endpoints..."
# gRPC endpoints (9090)
grpcurl -plaintext -d '{"locationID":"1","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}' localhost:9090 LocationService/EchoLocation
grpcurl -plaintext -d '{}' localhost:9090 Health/Check
grpcurl -plaintext -d '{}' localhost:9090 Health/AWSALBHealthCheck

echo "All tests passed." 