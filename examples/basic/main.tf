# Basic example — single account setup
#
# This example creates the three IAM roles in a single AWS account.
# For production, use separate accounts for CI/CD, principal, and TF states.

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      created_by = "infrahouse/terraform-aws-gha-admin"
    }
  }
}

# Prerequisites: GitHub OIDC provider
module "github-connector" {
  source  = "registry.infrahouse.com/infrahouse/gh-identity-provider/aws"
  version = "1.1.1"
}

# Prerequisites: State bucket
module "state-bucket" {
  source  = "registry.infrahouse.com/infrahouse/state-bucket/aws"
  version = "2.2.0"
  bucket  = "my-org-terraform-states"
}

# The gha-admin module
module "gha" {
  source  = "registry.infrahouse.com/infrahouse/gha-admin/aws"
  version = "3.5.1"
  providers = {
    aws          = aws
    aws.cicd     = aws
    aws.tfstates = aws
  }
  gh_org_name               = "my-org"
  repo_name                 = "my-repo"
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn
}

output "admin_role_arn" {
  value = module.gha.admin_role_arn
}

output "github_role_arn" {
  value = module.gha.github_role_arn
}

output "state_manager_role_arn" {
  value = module.gha.state_manager_role_arn
}
