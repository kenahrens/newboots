#!/bin/bash

# Deploy newboots application to Amazon ECS using CloudFormation
# Usage: ./deploy-ecs.sh [stack-name] [region]

set -e

STACK_NAME=${1:-newboots-ecs}
REGION=${2:-us-east-1}
TEMPLATE_FILE="cloudformation-ecs-newboots.yaml"
PARAMETERS_FILE="deploy-parameters.json"

echo "Deploying newboots to ECS..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
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
    --region $REGION

# Deploy the stack
echo "Deploying CloudFormation stack (with rollback disabled)..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION > /dev/null 2>&1; then
  echo "Stack exists, updating..."
  aws cloudformation update-stack \
    --template-body file://$TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --tags Key=Application,Value=newboots Key=Environment,Value=production Key=DeployedBy,Value=$(whoami) Key=DeployedAt,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --disable-rollback
else
  echo "Stack does not exist, creating..."
  aws cloudformation create-stack \
    --template-body file://$TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --tags Key=Application,Value=newboots Key=Environment,Value=production Key=DeployedBy,Value=$(whoami) Key=DeployedAt,Value=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --disable-rollback
fi

# Get stack outputs
echo "Getting stack outputs..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "Deployment completed successfully!"
echo ""
echo "To access your application:"
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
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
echo "aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION" 