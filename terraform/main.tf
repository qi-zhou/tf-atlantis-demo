# Simple Terraform configuration for Atlantis demo
terraform {
  required_version = ">= 1.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Simple null resource for demo
resource "null_resource" "example" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Hello from Atlantis! Timestamp: ${timestamp()}'"
  }
}

resource "null_resource" "demo" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Hello from Atlantis! Timestamp: ${timestamp()}'"
  }
}
