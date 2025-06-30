# Sidecar ALB, target group, listener, ECS service, and related resources moved here. 

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
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
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
  port        = 4143
  protocol    = "HTTP"
  protocol_version = "GRPC"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "HTTP"
    path     = "/Health/Check"
    matcher  = "0-12"
  }
}

resource "aws_lb_listener" "sidecar_http" {
  load_balancer_arn = aws_lb.sidecar.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:763455676074:certificate/b02e9925-ff7b-4f52-a6aa-dd35b8c21f97"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sidecar_grpc.arn
  }
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

resource "aws_iam_role_policy_attachment" "sidecar_task_policy" {
  role       = aws_iam_role.sidecar_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "sidecar" {
  family                   = "${var.stack_name}-newboots-sidecar"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.sidecar_task_role.arn
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
        },
        {
          containerPort = 4144
          hostPort      = 4144
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "TLS_OUT_UNWRAP", value = "true" },
        { name = "REVERSE_PROXY_PORT", value = "9090" },
        { name = "APP_POD_NAMESPACE", value = "ecs" },
        { name = "FORWARDER_ADDR", value = "forwarder.newboots-ecs.local:8888" },
        { name = "PROXY_TYPE", value = "dual" },
        { name = "CAPTURE_MODE", value = "proxy" },
        { name = "APP_LABEL", value = "newboots" },
        { name = "LOG_LEVEL", value = "debug" },
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
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:4144/healthz || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
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
        { name = "SERVER_PORT", value = "8080" },
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
          condition     = "HEALTHY"
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
      systemControls = []
    }
  ])
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
    container_name   = "goproxy"
    container_port   = 4143
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.sidecar_http]
} 