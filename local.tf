locals {
  module_version = "4.0.0"
  tags = {
    environment       = var.environment
    created_by_module = "infrahouse/gha-admin/aws"
  }
}
