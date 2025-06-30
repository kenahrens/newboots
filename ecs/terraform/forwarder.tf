# Speedscale forwarder service
resource "aws_ecs_task_definition" "forwarder" {
  family                   = "${var.stack_name}-forwarder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.sidecar_task_role.arn
  task_role_arn            = aws_iam_role.sidecar_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "forwarder"
      image     = "gcr.io/speedscale/forwarder:v2.3.586"
      cpu       = 0
      essential = true
      portMappings = [
        {
          containerPort = 8888
        }
      ]
      environment = [
        { name = "SPEEDSCALE_APP_URL", value = var.speedscale_app_url },
        { name = "GRPC_PORT", value = "8888" },
        { name = "LOG_LEVEL", value = "debug" }
      ],
      secrets = [
        {
          name      = "SPEEDSCALE_API_KEY"
          valueFrom = var.speedscale_api_key_secret_arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ecs/forwarder"
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
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
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.forwarder.arn
  }
}

resource "aws_service_discovery_private_dns_namespace" "newboots" {
  name = "newboots-ecs.local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "forwarder" {
  name = "forwarder"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.newboots.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
