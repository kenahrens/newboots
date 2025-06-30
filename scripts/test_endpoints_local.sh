#!/bin/bash
set -e
set -x

# Set your local gRPC host here
BASELINE_GRPC_HOST="localhost:9090"
GRPCURL_OPTS="-plaintext"

echo "Testing local gRPC endpoints..."
for i in {1..3}; do
  grpcurl $GRPCURL_OPTS -d '{"locationID":"'$i'","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}' $BASELINE_GRPC_HOST LocationService/EchoLocation || exit 1
  grpcurl $GRPCURL_OPTS -d '{}' $BASELINE_GRPC_HOST Health/Check || exit 1
  grpcurl $GRPCURL_OPTS -d '{}' $BASELINE_GRPC_HOST Health/AWSALBHealthCheck || exit 1
done

echo "Local gRPC checks passed."
