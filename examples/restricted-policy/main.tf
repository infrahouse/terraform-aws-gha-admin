# Restricted policy example
#
# This example uses a less permissive admin policy and allows
# the GitHub role to assume roles in additional accounts.

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      created_by = "infrahouse/terraform-aws-gha-admin"
    }
  }
}

provider "aws" {
  alias  = "cicd"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/admin"
  }
  default_tags {
    tags = {
      created_by = "infrahouse/terraform-aws-gha-admin"
    }
  }
}

provider "aws" {
  alias  = "tfstates"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/admin"
  }
  default_tags {
    tags = {
      created_by = "infrahouse/terraform-aws-gha-admin"
    }
  }
}

module "gha" {
  source  = "registry.infrahouse.com/infrahouse/gha-admin/aws"
  version = "3.5.1"
  providers = {
    aws          = aws
    aws.cicd     = aws.cicd
    aws.tfstates = aws.tfstates
  }
  gh_org_name               = "my-org"
  repo_name                 = "my-repo"
  state_bucket              = "my-org-terraform-states"
  terraform_locks_table_arn = "arn:aws:dynamodb:us-west-2:222222222222:table/terraform-locks"

  # Use PowerUserAccess instead of AdministratorAccess
  admin_policy_name = "PowerUserAccess"

  # Allow assuming roles in a staging account
  allowed_arns = [
    "arn:aws:iam::333333333333:role/ih-tf-my-repo-admin",
    "arn:aws:iam::333333333333:role/ih-tf-my-repo-state-manager",
  ]

  # Allow a CI/CD admin to also use these roles
  trusted_arns = [
    "arn:aws:iam::111111111111:role/admin",
  ]
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
