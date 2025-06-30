#!/bin/bash
set -e
set -x

# Usage: TARGET_ENV=cloud ./test_endpoints.sh

# Set your ALB DNS names here
BASELINE_ALB="newboots-ecs-alb-baseline-1833832424.us-east-1.elb.amazonaws.com"
SIDECAR_ALB="newboots-ecs-alb-sidecar-1871298899.us-east-1.elb.amazonaws.com"
AWS_REGION="us-east-1"
AWS_PROFILE="demo"

# Target group ARNs (update if needed)
BASELINE_TG_ARN=arn:aws:elasticloadbalancing:us-east-1:763455676074:targetgroup/newboots-ecs-tg-baseline-grpc/ea6f93e7dca1c7fa
SIDECAR_TG_ARN=arn:aws:elasticloadbalancing:us-east-1:763455676074:targetgroup/newboots-ecs-tg-sidecar-grpc/2ad33c6230bc5df2

# 1. Check ALB target group health
for TG_ARN in "$BASELINE_TG_ARN" "$SIDECAR_TG_ARN"; do
  echo "Checking health for target group: $TG_ARN"
  AWS_PAGER=cat aws elbv2 describe-target-health --region "$AWS_REGION" --profile "$AWS_PROFILE" --target-group-arn "$TG_ARN"
done

# 2. Test baseline ALB with gRPC
BASELINE_GRPC_HOST="$BASELINE_ALB:443"
GRPCURL_OPTS="-insecure"
echo "Testing baseline gRPC endpoints..."
for i in {1..3}; do
  grpcurl $GRPCURL_OPTS -d '{"locationID":"'$i'","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}' $BASELINE_GRPC_HOST LocationService/EchoLocation
  grpcurl $GRPCURL_OPTS -d '{}' $BASELINE_GRPC_HOST Health/Check
  response=$(grpcurl $GRPCURL_OPTS -H "user-agent: ELB-HealthChecker/2.0" -d '{}' $BASELINE_GRPC_HOST Health/AWSALBHealthCheck 2>&1 || true)
  if ! echo "$response" | grep -q "Unimplemented" || ! echo "$response" | grep -q "Health check successful"; then
    echo "Health check failed for baseline"
    exit 1
  fi
done

echo "Baseline gRPC checks passed."

# 3. Test sidecar ALB with gRPC
SIDECAR_GRPC_HOST="$SIDECAR_ALB:443"
echo "Testing sidecar gRPC endpoints..."
for i in {1..3}; do
  grpcurl $GRPCURL_OPTS -d '{"locationID":"'$i'","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}' $SIDECAR_GRPC_HOST LocationService/EchoLocation
  grpcurl $GRPCURL_OPTS -d '{}' $SIDECAR_GRPC_HOST Health/Check
  response=$(grpcurl $GRPCURL_OPTS -H "user-agent: ELB-HealthChecker/2.0" -d '{}' $SIDECAR_GRPC_HOST Health/AWSALBHealthCheck 2>&1 || true)
  if ! echo "$response" | grep -q "Unimplemented" || ! echo "$response" | grep -q "Health check successful"; then
    echo "Health check failed for sidecar"
    exit 1
  fi
done

echo "Sidecar gRPC checks passed."

# 4. Send 10 gRPC transactions to sidecar
for i in {1..10}; do
  grpcurl $GRPCURL_OPTS -d '{"locationID":"'$i'","latitude":1.0,"longitude":2.0,"macAddress":"aa:bb:cc:dd:ee:ff","ipv4":"127.0.0.1"}' $SIDECAR_GRPC_HOST LocationService/EchoLocation > /dev/null
  grpcurl $GRPCURL_OPTS -d '{}' $SIDECAR_GRPC_HOST Health/Check > /dev/null
  grpcurl $GRPCURL_OPTS -H "user-agent: ELB-HealthChecker/2.0" -d '{}' $SIDECAR_GRPC_HOST Health/AWSALBHealthCheck > /dev/null 2>&1 || true
done

# 5. Manual Speedscale Check
# The following check is currently performed manually.
# After running this script, please check Speedscale to ensure traffic has been ingested.
#
# echo "Sent 10 gRPC transactions to sidecar. Waiting 1 minute for Speedscale to ingest traffic..."
# sleep 60
#
# Set Speedscale variables (allow override)
# APP_POD_NAME="${APP_POD_NAME:-newboots}"
# APP_POD_NAMESPACE="${APP_POD_NAMESPACE:-ecs}"
# CLUSTER_NAME="${CLUSTER_NAME:-newboots-ecs-cluster}"
#
# Poll Speedscale for up to 3 minutes (12 times, every 15s)
# for i in {1..12}; do
#   echo "Checking Speedscale for service messages (attempt $i/12)..."
#   speedctl get service messages "$APP_POD_NAME" --namespace "$APP_POD_NAMESPACE" --cluster "$CLUSTER_NAME" --from now-5m > speedscale_output.txt 2>&1
#   if grep -q "newboots" speedscale_output.txt; then
#     echo "Traffic detected in Speedscale!"
#     cat speedscale_output.txt
#     exit 0
#   fi
#   sleep 15
# done
#
# echo "No traffic detected in Speedscale after 3 minutes."
# if [ ! -f speedscale_output.txt ]; then
#     echo "speedscale_output.txt not found!"
#     exit 1
# fi
# exit 1

echo "All tests passed." 