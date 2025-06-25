terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "demo"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#---------------------------------------------------------------------------
# Shared Resources
#---------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.stack_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.stack_name}-cluster"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb_baseline" {
  name        = "${var.stack_name}-alb-baseline-sg"
  description = "Security group for baseline ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "baseline" {
  name               = "${var.stack_name}-alb-baseline"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_baseline.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "baseline_grpc" {
  name        = "${var.stack_name}-tg-baseline-grpc"
  port        = 9090
  protocol    = "GRPC"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "GRPC"
    path     = "/grpc.health.v1.Health/Check"
    port     = "9090"
  }
}

resource "aws_lb_listener" "baseline_http" {
  load_balancer_arn = aws_lb.baseline.arn
  port              = 80
  protocol          = "GRPC"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.baseline_grpc.arn
  }
  depends_on = [aws_lb_target_group.baseline_grpc]
}

resource "aws_security_group" "alb_sidecar" {
  name        = "${var.stack_name}-alb-sidecar-sg"
  description = "Security group for sidecar ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "sidecar" {
  name               = "${var.stack_name}-alb-sidecar"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sidecar.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "sidecar_grpc" {
  name        = "${var.stack_name}-tg-sidecar-grpc"
  port        = 9090
  protocol    = "GRPC"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "GRPC"
    path     = "/grpc.health.v1.Health/Check"
    port     = "9090"
  }
}

resource "aws_lb_listener" "sidecar_http" {
  load_balancer_arn = aws_lb.sidecar.arn
  port              = 80
  protocol          = "GRPC"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sidecar_grpc.arn
  }
  depends_on = [aws_lb_target_group.sidecar_grpc]
}

resource "aws_security_group" "ecs" {
  name        = "${var.stack_name}-ecs-sg"
  description = "Security group for newboots ECS service"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 9090
    to_port         = 9090
    security_groups = [aws_security_group.alb_baseline.id, aws_security_group.alb_sidecar.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.stack_name}-ecs-sg"
  }
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.stack_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:newboots-google-credentials*",
      var.speedscale_api_key_secret_arn,
      var.speedscale_tls_cert_secret_arn,
      var.speedscale_tls_key_secret_arn,
    ]
  }
}

resource "aws_iam_policy" "secrets_access" {
  name   = "${var.stack_name}-secrets-access"
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

#---------------------------------------------------------------------------
# Speedscale Instrumented Application
#---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "sidecar" {
  name              = "/ecs/${var.stack_name}/newboots-sidecar"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "forwarder" {
  name              = "/ecs/${var.stack_name}/forwarder"
  retention_in_days = 7
}

resource "aws_iam_role" "sidecar_task_role" {
  name = "${var.stack_name}-sidecar-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "sidecar_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.sidecar.arn,
      aws_cloudwatch_log_group.forwarder.arn
    ]
  }
}

resource "aws_iam_policy" "sidecar_logs" {
  name   = "${var.stack_name}-sidecar-logs"
  policy = data.aws_iam_policy_document.sidecar_logs.json
}

resource "aws_iam_role_policy_attachment" "sidecar_logs" {
  role       = aws_iam_role.sidecar_task_role.name
  policy_arn = aws_iam_policy.sidecar_logs.arn
}

resource "aws_iam_role_policy_attachment" "sidecar_secrets_access" {
  role       = aws_iam_role.sidecar_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${var.stack_name}.local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "forwarder" {
  name = "forwarder"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "forwarder" {
  name        = "${var.stack_name}-forwarder-sg"
  description = "SG for Speedscale forwarder"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8888
    to_port         = 8888
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-forwarder-sg"
  }
}

resource "aws_ecs_task_definition" "forwarder" {
  family                   = "${var.stack_name}-forwarder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.sidecar_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "forwarder"
      image     = "gcr.io/speedscale/forwarder:v2.3.586"
      essential = true
      portMappings = [
        {
          containerPort = 8888
        }
      ]
      secrets = [
        {
          name      = "SPEEDSCALE_API_KEY"
          valueFrom = var.speedscale_api_key_secret_arn
        }
      ]
      environment = [
        { name = "CLUSTER_NAME", value = aws_ecs_cluster.main.name },
        { name = "SPEEDSCALE_APP_URL", value = var.speedscale_app_url },
        { name = "SUB_TENANT_STREAM", value = var.speedscale_sub_tenant_stream },
        { name = "TENANT_BUCKET", value = var.speedscale_tenant_bucket },
        { name = "TENANT_NAME", value = var.speedscale_tenant_name },
        { name = "TENANT_ID", value = var.speedscale_tenant_id },
        { name = "TENANT_REGION", value = var.speedscale_tenant_region }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.forwarder.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "forwarder"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "forwarder" {
  name            = "${var.stack_name}-forwarder"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.forwarder.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.forwarder.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.forwarder.arn
  }
}

resource "aws_ecs_task_definition" "sidecar" {
  family                   = "${var.stack_name}-newboots-sidecar"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.sidecar_task_role.arn

  volume {
    name = "speedscale"
  }

  container_definitions = jsonencode([
    {
      name        = "init"
      image       = "amazon/aws-cli:2.8.4"
      cpu         = 0
      essential   = false
      entryPoint  = ["bash"]
      command     = [
        "-c",
        "mkdir -p /etc/ssl/speedscale && aws secretsmanager get-secret-value --secret-id newboots-tls-cert --query SecretString --output text >> /etc/ssl/speedscale/tls.crt && aws secretsmanager get-secret-value --secret-id newboots-tls-key --query SecretString --output text >> /etc/ssl/speedscale/tls.key"
      ]
      environment = []
      mountPoints = [
        {
          sourceVolume = "speedscale"
          containerPath = "/etc/ssl/speedscale"
        }
      ]
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ecs/init"
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    },
    {
      name      = "goproxy"
      image     = "gcr.io/speedscale/goproxy:v2.3"
      cpu       = 0
      essential = true
      portMappings = [
        {
          containerPort = 4143
          hostPort      = 4143
          protocol      = "tcp"
        },
        {
          containerPort = 4140
          hostPort      = 4140
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "TLS_OUT_UNWRAP", value = "true" },
        { name = "REVERSE_PROXY_PORT", value = "8080" },
        { name = "APP_POD_NAMESPACE", value = "ecs" },
        { name = "FORWARDER_ADDR", value = "forwarder.ecs.local:8888" },
        { name = "PROXY_TYPE", value = "dual" },
        { name = "CAPTURE_MODE", value = "proxy" },
        { name = "APP_LABEL", value = "newboots" },
        { name = "LOG_LEVEL", value = "info" },
        { name = "APP_POD_NAME", value = "newboots" },
        { name = "PROXY_PROTOCOL", value = "tcp:http" }
      ]
      mountPoints = [
        {
          sourceVolume = "speedscale"
          containerPath = "/etc/ssl/speedscale"
        }
      ]
      volumesFrom = []
      dependsOn = [
        {
          containerName = "init"
          condition     = "SUCCESS"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ecs/goproxy"
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    },
    {
      name      = "newboots"
      image     = var.container_image
      cpu       = 0
      essential = true
      portMappings = [
        {
          containerPort = 9090
        }
      ]
      environment = [
        { name = "SERVER_PORT", value = "9090" },
        { name = "SSL_CERT_FILE", value = "/etc/ssl/speedscale/tls.crt" },
        { name = "HTTP_PROXY", value = "http://localhost:4140" },
        { name = "SPRING_PROFILES_ACTIVE", value = "development" },
        { name = "HTTPS_PROXY", value = "http://localhost:4140" }
      ]
      mountPoints = [
        {
          sourceVolume = "speedscale"
          containerPath = "/etc/ssl/speedscale"
        }
      ]
      volumesFrom = []
      dependsOn = [
        {
          containerName = "init"
          condition     = "SUCCESS"
        },
        {
          containerName = "goproxy"
          condition     = "START"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ecs/newboots"
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:9090/ || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
      }
      systemControls = []
    }
  ])
}

resource "aws_ecs_service" "baseline" {
  name            = "${var.stack_name}-baseline"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sidecar.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.baseline_grpc.arn
    container_name   = "newboots"
    container_port   = 9090
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.baseline_http]
}

resource "aws_ecs_service" "sidecar" {
  name            = "${var.stack_name}-sidecar"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sidecar.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sidecar_grpc.arn
    container_name   = "newboots"
    container_port   = 9090
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.sidecar_http]
} 