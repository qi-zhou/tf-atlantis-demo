# Outputs for simple Atlantis demo

output "demo_resource_id" {
  description = "ID of the demo null resource"
  value       = null_resource.example.id
}

output "demo_message" {
  description = "Demo message"
  value       = "Atlantis demo completed successfully!"
}
