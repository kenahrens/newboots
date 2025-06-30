output "baseline_app_url" {
  description = "URL for the baseline application"
  value       = "https://${aws_lb.baseline.dns_name}"
}

output "sidecar_app_url" {
  description = "URL for the application with the Speedscale sidecar"
  value       = "https://${aws_lb.sidecar.dns_name}"
} 