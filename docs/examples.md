# Examples

## Basic Setup

Minimal configuration with all three providers pointing to the same account:

```hcl
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
  state_bucket              = "my-terraform-states"
  terraform_locks_table_arn = "arn:aws:dynamodb:us-west-2:123456789012:table/terraform-locks"
}
```

## Multi-Account Setup

Production setup with separate accounts for CI/CD, infrastructure, and state:

```hcl
provider "aws" {
  region = "us-west-2"
  # Principal account credentials
}

provider "aws" {
  alias  = "cicd"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/admin"
  }
}

provider "aws" {
  alias  = "tfstates"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/admin"
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
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn
}
```

## Restricted Admin Policy

Use a less permissive policy instead of AdministratorAccess:

```hcl
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
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn

  # Use PowerUserAccess instead of AdministratorAccess
  admin_policy_name = "PowerUserAccess"
}
```

## Cross-Account Role Assumption

Allow the GitHub role to assume roles in additional accounts:

```hcl
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
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn

  # Allow assuming roles in additional accounts
  allowed_arns = [
    "arn:aws:iam::333333333333:role/ih-tf-my-repo-admin",
    "arn:aws:iam::333333333333:role/ih-tf-my-repo-state-manager",
  ]
}
```

## Central CI/CD Repository

For a repository that manages multiple AWS accounts and needs to assume any role:

```hcl
module "gha" {
  source  = "registry.infrahouse.com/infrahouse/gha-admin/aws"
  version = "3.5.1"
  providers = {
    aws          = aws
    aws.cicd     = aws.cicd
    aws.tfstates = aws.tfstates
  }
  gh_org_name               = "my-org"
  repo_name                 = "aws-control"
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn

  # Allow assuming all roles for central management
  allow_assume_all_roles = true
}
```

## Additional Trusted Principals

Allow human operators or other automation to also assume the admin and state-manager roles:

```hcl
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
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn

  # Allow an admin role from the CI/CD account to also assume these roles
  trusted_arns = [
    "arn:aws:iam::111111111111:role/admin",
  ]
}
```

## GitHub Actions Workflow

Example GitHub Actions workflow using the roles created by this module.

> **Note**: This example uses `ubuntu-latest` for simplicity. InfraHouse workflows
> use self-hosted runners because GitHub-hosted runners don't have the `ih-registry`
> command. If you use `registry.infrahouse.com` as your module source, you'll need
> a self-hosted runner with `ih-registry` configured.

```yaml
name: Terraform CI/CD

on:
  push:
    branches: [main]
  pull_request:

permissions:
  id-token: write
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::CICD_ACCOUNT:role/ih-tf-my-repo-github
          aws-region: us-west-2

      - uses: hashicorp/setup-terraform@v3

      - run: terraform init
      - run: terraform plan

  apply:
    if: github.ref == 'refs/heads/main'
    needs: plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::CICD_ACCOUNT:role/ih-tf-my-repo-github
          aws-region: us-west-2

      - uses: hashicorp/setup-terraform@v3

      - run: terraform init
      - run: terraform apply -auto-approve
```
