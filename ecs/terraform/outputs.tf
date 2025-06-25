output "baseline_app_url" {
  description = "URL for the baseline application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "sidecar_app_url" {
  description = "URL for the application with the Speedscale sidecar"
  value       = "http://${aws_lb.main.dns_name}/sidecar/"
} 