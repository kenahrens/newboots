#!/bin/bash
set -e
set -x

# Usage: ./validate_deployment.sh

AWS_REGION="us-east-1"
AWS_PROFILE="demo"
CLUSTER_NAME="newboots-ecs-cluster"

# Check the status of the baseline service
BASELINE_STATUS=$(AWS_PAGER="" aws ecs describe-services --cluster $CLUSTER_NAME --services newboots-ecs-baseline --profile $AWS_PROFILE --query "services[0].deployments[0].rolloutState" --output text)
if [ "$BASELINE_STATUS" != "COMPLETED" ]; then
  echo "Baseline service deployment is not complete. Status: $BASELINE_STATUS"
  exit 1
fi

# Check the status of the sidecar service
SIDECAR_STATUS=$(AWS_PAGER="" aws ecs describe-services --cluster $CLUSTER_NAME --services newboots-ecs-sidecar --profile $AWS_PROFILE --query "services[0].deployments[0].rolloutState" --output text)
if [ "$SIDECAR_STATUS" != "COMPLETED" ]; then
  echo "Sidecar service deployment is not complete. Status: $SIDECAR_STATUS"
  exit 1
fi

# Check for the forwarder service
FORWARDER_STATUS=$(AWS_PAGER="" aws ecs describe-services --cluster $CLUSTER_NAME --services forwarder --profile $AWS_PROFILE --query "services[0].status" --output text)
if [ "$FORWARDER_STATUS" == "None" ]; then
    echo "Forwarder service is missing."
    exit 1
fi

echo "All deployments are complete and services are running."
exit 0
