locals {
  module_version = "4.1.0"
  tags = {
    environment       = var.environment
    created_by_module = "infrahouse/gha-admin/aws"
  }

  name_prefix   = var.name_prefix == "" ? "ih-tf-" : "ih-tf-${var.name_prefix}-"
  repo_budget   = 64 - length(local.name_prefix) - length("-state-manager")
  repo_short    = substr(var.repo_name, 0, local.repo_budget)
  role_basename = "${local.name_prefix}${local.repo_short}"
}
