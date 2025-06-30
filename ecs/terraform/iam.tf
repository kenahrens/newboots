resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.stack_name}-secrets-policy"
  description = "Allows ECS tasks to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = [
          var.speedscale_api_key_secret_arn,
          var.speedscale_tls_cert_secret_arn,
          var.speedscale_tls_key_secret_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sidecar_secrets_policy_attachment" {
  role       = aws_iam_role.sidecar_task_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}
