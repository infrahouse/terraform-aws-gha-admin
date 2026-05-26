variable "environment" {
  description = "Environment name."
  type        = string
}

variable "gh_org_name" {
  description = "GitHub organization name."
  type        = string
}

variable "name_prefix" {
  description = "Optional disambiguator for role names."
  type        = string
  default     = ""
}

variable "repo_name" {
  description = "Repository name in GitHub. Without the organization part."
}
