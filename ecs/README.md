# TheBot ECS Deployment

> **Note:** Always set `PAGER=cat` for AWS CLI commands in this repo to ensure non-interactive output and avoid missing or paged results.

> **Pre-requisite:**
> You must manually create an AWS Secrets Manager secret named `newboots-google-credentials` containing your Google service account JSON credentials. This is required for the application to start and access Google Pub/Sub.
>
> To create the secret via CLI:
> ```sh
> aws secretsmanager create-secret \
>   --name newboots-google-credentials \
>   --description "Google Application Credentials for newboots ECS app" \
>   --secret-string file:///path/to/your/auth.json \
>   --region us-east-1 \
>   --profile <your-aws-profile>
> ```
> Replace `/path/to/your/auth.json` with the path to your Google service account JSON file.

This directory contains CloudFormation templates and deployment scripts for deploying the newboots Spring Boot application to Amazon ECS with Fargate.

## Files

- `cloudformation-ecs-newboots.yaml` - Main CloudFormation template
- `deploy-parameters.json` - Parameters file template  
- `deploy-ecs.sh` - Deployment script
- `README.md` - This documentation

## Prerequisites

1. **AWS CLI** - Install and configure with appropriate permissions
2. **VPC and Subnets** - You need an existing VPC with:
   - At least 2 private subnets (for ECS tasks)
   - At least 2 public subnets (for the Application Load Balancer)
3. **Docker Image** - The container image should be available in a registry accessible to ECS

## Quick Start

1. **Configure Parameters**
   ```bash
   cp deploy-parameters.json deploy-parameters.json.backup
   # Edit deploy-parameters.json with your actual values
   ```

2. **Update the parameters file** with your AWS resource IDs:
   - `VpcId`: Your VPC ID (e.g., `vpc-12345678`)
   - `SubnetIds`: Comma-separated private subnet IDs for ECS tasks
   - `PublicSubnetIds`: Comma-separated public subnet IDs for ALB
   - `ContainerImage`: Docker image URI (default: `ghcr.io/kenahrens/newboots:latest`)

3. **Deploy**
   ```bash
   ./deploy-ecs.sh
   ```

   Or specify custom stack name and region:
   ```bash
   ./deploy-ecs.sh my-newboots-stack us-west-2
   ```

## Architecture

The CloudFormation template creates:

### Core ECS Resources
- **ECS Cluster** with Container Insights enabled
- **ECS Service** running on Fargate
- **Task Definition** with the newboots container
- **CloudWatch Log Group** for application logs

### Networking
- **Application Load Balancer** (ALB) in public subnets
- **Target Group** for health checks and load balancing
- **Security Groups** for ALB and ECS tasks

### Auto Scaling
- **Application Auto Scaling** target and policy
- CPU-based scaling (target: 70% CPU utilization)
- Scale between 2-10 tasks

### IAM Roles
- **Task Execution Role** for ECS to pull images and logs
- **Task Role** for application permissions

### Optional Features
- **AWS Secrets Manager** integration for Google credentials
- **Health checks** using Spring Boot Actuator

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| VpcId | VPC ID | Required | VPC where resources will be created |
| SubnetIds | Subnet IDs | Required | Private subnets for ECS tasks |
| PublicSubnetIds | Subnet IDs | Required | Public subnets for ALB |
| ContainerImage | String | `ghcr.io/kenahrens/newboots:latest` | Docker image URI |
| ContainerPort | Number | 8080 | Application port |
| DesiredCount | Number | 2 | Initial number of tasks |
| TaskCpu | String | '512' | CPU units (256, 512, 1024, 2048, 4096) |
| TaskMemory | String | '1024' | Memory in MB |
| Environment | String | production | Environment name |
| GoogleApplicationCredentials | String | '' | Base64 encoded Google credentials JSON |

## Outputs

After deployment, the stack provides these outputs:

- **LoadBalancerURL** - Main application URL
- **HealthCheckURL** - Health check endpoint (`/actuator/health`)
- **GreetingURL** - Greeting API endpoint (`/greeting`)
- **ClusterName** - ECS cluster name
- **ServiceName** - ECS service name

## Application Endpoints

Once deployed, your application will be available at:

- **Home**: `http://<alb-dns>/`
- **Health Check**: `http://<alb-dns>/actuator/health`
- **Greeting**: `http://<alb-dns>/greeting?name=YourName`
- **Location**: `http://<alb-dns>/location`
- **Customer Lookup**: `http://<alb-dns>/customer/lookup`
- **NASA**: `http://<alb-dns>/nasa`
- **Space**: `http://<alb-dns>/space`
- **Zip**: `http://<alb-dns>/zip`

## Monitoring and Logs

- **CloudWatch Logs**: Available in log group `/ecs/<stack-name>/newboots`
- **Container Insights**: Enabled for detailed container metrics
- **Health Checks**: Automatic health monitoring via ALB and ECS

## Security

- ECS tasks run in private subnets
- Only ALB accepts public traffic (ports 80/443)
- Security groups restrict traffic between ALB and ECS
- IAM roles follow least privilege principle
- Secrets stored in AWS Secrets Manager

## Customization

### Environment Variables
Add custom environment variables in the `TaskDefinition` > `ContainerDefinitions` > `Environment` section.

### Resource Scaling
Modify auto scaling parameters in the `AutoScalingPolicy` section:
- Target CPU utilization
- Min/Max capacity
- Scale-out/Scale-in cooldowns

### HTTPS Support
To enable HTTPS:
1. Add an SSL certificate to AWS Certificate Manager
2. Create an HTTPS listener (port 443) in the ALB
3. Redirect HTTP to HTTPS

## Troubleshooting

### Common Issues

1. **Service fails to start**
   - Check CloudWatch logs: `/ecs/<stack-name>/newboots`
   - Verify container image is accessible
   - Check security group rules

2. **Health checks failing**
   - Ensure `/actuator/health` endpoint is working
   - Verify container port matches `ContainerPort` parameter
   - Check application startup time vs health check timing

3. **Cannot access application**
   - Verify ALB security group allows inbound traffic
   - Check route tables for public subnets
   - Ensure NAT gateway/instance for private subnet internet access

### Debugging Commands

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name newboots-ecs

# View ECS service events
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Check task logs
aws logs get-log-events --log-group-name /ecs/<stack-name>/newboots --log-stream-name <stream-name>

# View ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Cleanup

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name newboots-ecs --region us-east-1
```

## Cost Optimization

- Use smaller task sizes for development (`TaskCpu: '256'`, `TaskMemory: '512'`)
- Reduce `DesiredCount` for non-production environments
- Enable auto scaling to handle variable load efficiently
- Consider using Spot instances for non-critical workloads (requires EC2 launch type)

## Support

For issues with the newboots application itself, check the main project documentation.
For AWS ECS-specific issues, consult the [AWS ECS documentation](https://docs.aws.amazon.com/ecs/). 