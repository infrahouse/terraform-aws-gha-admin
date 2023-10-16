output "admin_role_arn" {
  description = "ARN of the `ih-tf-{var.repo_name}-admin` role"
  value       = aws_iam_role.admin.arn
}

output "github_role_arn" {
  description = "ARN of the `ih-tf-{var.repo_name}-github` role"
  value       = aws_iam_role.github.arn
}

output "state_manager_role_arn" {
  description = "ARN of the `ih-tf-{var.repo_name}-state-manager` role"
  value       = module.state-manager.state_manager_role_arn
}
