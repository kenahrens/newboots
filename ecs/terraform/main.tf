terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
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

resource "aws_security_group" "ecs" {
  name        = "${var.stack_name}-ecs-sg"
  description = "Security group for newboots ECS service (shared by baseline and sidecar)"
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

# Baseline and sidecar resources have been moved to baseline.tf and sidecar.tf. Only shared resources remain here. 