#!/bin/bash

# Deploy newboots application to Amazon ECS using CloudFormation
# Usage: ./deploy-ecs.sh [stack-name] [region] [profile]

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

STACK_NAME=${1:-newboots-ecs}
REGION=${2:-us-east-1}
PROFILE=${3:-demo}
TEMPLATE_FILE="$SCRIPT_DIR/cloudformation-ecs-newboots.yaml"
PARAMETERS_FILE="$SCRIPT_DIR/deploy-parameters.json"

echo "Deploying newboots to ECS..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Profile: $PROFILE"
echo "Template: $TEMPLATE_FILE"
echo "Parameters: $PARAMETERS_FILE"

# Check if files exist
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: CloudFormation template file '$TEMPLATE_FILE' not found!"
    exit 1
fi

if [ ! -f "$PARAMETERS_FILE" ]; then
    echo "Error: Parameters file '$PARAMETERS_FILE' not found!"
    echo "Please copy deploy-parameters.json.example to deploy-parameters.json and update the values."
    exit 1
fi

# Validate the CloudFormation template
echo "Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region $REGION \
    --profile $PROFILE

# Deploy the stack
echo "Deploying CloudFormation stack (with rollback disabled)..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --profile $PROFILE > /dev/null 2>&1; then
  echo "Stack exists, updating..."
  aws cloudformation update-stack \
    --template-body file://$TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --profile $PROFILE \
    --tags Key=Application,Value=newboots Key=Environment,Value=production Key=DeployedBy,Value=$(whoami) Key=DeployedAt,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --disable-rollback
  echo "Waiting for stack update to complete..."
  aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $REGION --profile $PROFILE
else
  echo "Stack does not exist, creating..."
  aws cloudformation create-stack \
    --template-body file://$TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --profile $PROFILE \
    --tags Key=Application,Value=newboots Key=Environment,Value=production Key=DeployedBy,Value=$(whoami) Key=DeployedAt,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --disable-rollback
  echo "Waiting for stack creation to complete..."
  aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION --profile $PROFILE
fi

# Get stack outputs
echo "Getting stack outputs..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --profile $PROFILE \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "Deployment completed successfully!"
echo ""
echo "To access your application:"
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --profile $PROFILE \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$ALB_URL" ]; then
    echo "Application URL: $ALB_URL"
    echo "Health Check: $ALB_URL/actuator/health"
    echo "Greeting API: $ALB_URL/greeting?name=YourName"
else
    echo "Use the LoadBalancerURL from the stack outputs above."
fi

echo ""
echo "To delete the stack when no longer needed:"
echo "aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION --profile $PROFILE" 