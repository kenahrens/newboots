variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service (should be private subnets)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the Application Load Balancer"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image URI for the newboots application"
  type        = string
  default     = "ghcr.io/kenahrens/newboots-server:latest"
}

variable "container_port" {
  description = "Port on which the newboots application runs"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory (MB) for the task"
  type        = string
  default     = "1024"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "google_application_credentials" {
  description = "Google Application Credentials JSON (base64 encoded)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "speedscale_api_key_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for the Speedscale API Key"
  type        = string
  sensitive   = true
}

variable "speedscale_app_url" {
  description = "Speedscale App URL"
  type        = string
  default     = "app.speedscale.com"
}

variable "speedscale_sub_tenant_name" {
  description = "Speedscale Sub Tenant Name"
  type        = string
  default     = "default"
}

variable "speedscale_sub_tenant_stream" {
  description = "Speedscale Sub Tenant Stream"
  type        = string
}

variable "speedscale_tenant_bucket" {
  description = "Speedscale Tenant Bucket"
  type        = string
}

variable "speedscale_tenant_name" {
  description = "Speedscale Tenant Name"
  type        = string
}

variable "speedscale_tenant_id" {
  description = "Speedscale Tenant ID"
  type        = string
}

variable "speedscale_tenant_region" {
  description = "Speedscale Tenant Region"
  type        = string
  default     = "us-east-1"
}

variable "speedscale_tls_cert_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for tls.crt"
  type        = string
}

variable "speedscale_tls_key_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for tls.key"
  type        = string
}

variable "stack_name" {
  description = "Name of the stack, used to name resources"
  type        = string
  default     = "newboots-ecs"
} 