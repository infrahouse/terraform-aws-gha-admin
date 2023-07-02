
variable "repo_name" {
  description = "Repository name in GitHub. Without the organization part."
}

variable "gh_identity_provider_arn" {
  description = "GitHub OpenID identity provider"
}

variable "gh_org_name" {
  description = "GitHub organization name"
  type        = string
  default     = "infrahouse"
}

variable "state_bucket" {
  description = "Name of the S3 bucket with the state"
}

