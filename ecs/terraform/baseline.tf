# Baseline ALB, target group, listener, ECS service, and related resources moved here. 

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
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "TCP"
    port     = "9090"
  }
}

resource "aws_lb_listener" "baseline_http" {
  load_balancer_arn = aws_lb.baseline.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:763455676074:certificate/b02e9925-ff7b-4f52-a6aa-dd35b8c21f97"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.baseline_grpc.arn
  }
}

resource "aws_iam_role" "baseline_task_role" {
  name = "${var.stack_name}-baseline-task-role"

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

resource "aws_iam_role_policy_attachment" "baseline_task_policy" {
  role       = aws_iam_role.baseline_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "baseline" {
  family                   = "${var.stack_name}-baseline"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.baseline_task_role.arn
  task_role_arn            = aws_iam_role.baseline_task_role.arn

  container_definitions = jsonencode([
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
        { name = "SPRING_PROFILES_ACTIVE", value = "development" }
      ]
      mountPoints = []
      volumesFrom = []
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

resource "aws_ecs_service" "baseline" {
  name            = "${var.stack_name}-baseline"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.baseline.arn
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