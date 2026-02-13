variable "allowed_arns" {
  description = "A list of ARNs `ih-tf-{var.repo_name}-github` is allowed to assume besides `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` roles."
  type        = list(string)
  default     = []
}

variable "allow_assume_all_roles" {
  description = "If true the -github role may assume all possible roles."
  type        = bool
  default     = false
}

variable "admin_policy_name" {
  description = "Name of the IAM policy the `ih-tf-{var.repo_name}-admin` role will have. This is what the role can do."
  type        = string
  default     = "AdministratorAccess"
}

variable "trusted_arns" {
  description = "A list of ARNs besides `ih-tf-{var.repo_name}-github` that are allowed to assume the `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` role."
  type        = list(string)
  default     = []
}

variable "gh_org_name" {
  description = "GitHub organization name."
  type        = string
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) that you want to set for the specified role."
  type        = number
  default     = 12 * 3600
}

variable "repo_name" {
  description = "Repository name in GitHub. Without the organization part."
  type        = string
}

variable "state_bucket" {
  description = "Name of the S3 bucket with the state"
  type        = string
}

variable "terraform_locks_table_arn" {
  description = "DynamoDB table that holds Terraform state locks."
  type        = string
}
