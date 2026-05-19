locals {
  module_version = "3.6.1"
  tags = {
    environment       = var.environment
    created_by_module = "infrahouse/gha-admin/aws"
  }
}
