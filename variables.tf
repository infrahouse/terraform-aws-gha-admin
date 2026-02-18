variable "allowed_arns" {
  description = <<-EOT
    A list of ARNs `ih-tf-{var.repo_name}-github` is allowed to assume
    besides `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` roles.
  EOT
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
  description = <<-EOT
    A list of ARNs besides `ih-tf-{var.repo_name}-github` that are allowed to assume
    the `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` role.
  EOT
  type        = list(string)
  default     = []
}

variable "gh_org_name" {
  description = "GitHub organization name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.gh_org_name))
    error_message = "gh_org_name must contain only letters, numbers, and hyphens. Got: ${var.gh_org_name}"
  }
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) that you want to set for the specified role."
  type        = number
  default     = 12 * 3600

  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 900 and 43200 seconds. Got: ${var.max_session_duration}"
  }
}

variable "repo_name" {
  description = "Repository name in GitHub. Without the organization part."
  type        = string
}

variable "state_bucket" {
  description = "Name of the S3 bucket with the state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket))
    error_message = "state_bucket must be a valid S3 bucket name (3-63 chars, lowercase, numbers, hyphens, dots). Got: ${var.state_bucket}"
  }
}

variable "terraform_locks_table_arn" {
  description = "DynamoDB table that holds Terraform state locks."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:dynamodb:[a-z0-9-]+:[0-9]{12}:table/.+$", var.terraform_locks_table_arn))
    error_message = "terraform_locks_table_arn must be a valid DynamoDB table ARN. Got: ${var.terraform_locks_table_arn}"
  }
}
