# Getting Started

This guide walks you through setting up GitHub Actions CI/CD roles for a Terraform-managed AWS account.

## Prerequisites

Before you begin, ensure you have:

1. **Terraform** >= 1.5 installed
2. **AWS CLI** configured with credentials that can create IAM roles in all three accounts
3. **Three AWS accounts** (or a single account for testing):
    - **Principal account** — where your managed resources live
    - **CI/CD account** — where the GitHub OIDC provider is configured
    - **TF states account** — where Terraform state is stored
4. **A GitHub OIDC provider** in the CI/CD account
5. **An S3 bucket and DynamoDB table** for Terraform state

## Step 1: Create the GitHub OIDC Provider

The GitHub OIDC provider must exist in the CI/CD account before deploying this module.
Use the [gh-identity-provider](https://registry.infrahouse.com/infrahouse/gh-identity-provider/aws)
module:

```hcl
module "github-connector" {
  source  = "registry.infrahouse.com/infrahouse/gh-identity-provider/aws"
  version = "1.1.1"
}
```

This only needs to be done once per CI/CD account — all repositories share the same OIDC provider.

## Step 2: Create the State Bucket

Use the [state-bucket](https://registry.infrahouse.com/infrahouse/state-bucket/aws)
module to create an S3 bucket and DynamoDB lock table in the TF states account:

```hcl
module "state-bucket" {
  source  = "registry.infrahouse.com/infrahouse/state-bucket/aws"
  version = "2.2.0"
  providers = {
    aws = aws.tfstates
  }
  bucket = "my-org-terraform-states"
}
```

## Step 3: Configure Providers

Set up three AWS provider configurations pointing to each account:

```hcl
# Principal account — where managed resources live
provider "aws" {
  region = "us-west-2"
}

# CI/CD account — where GitHub OIDC provider is
provider "aws" {
  alias  = "cicd"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::CICD_ACCOUNT_ID:role/admin"
  }
}

# TF states account — where Terraform state is stored
provider "aws" {
  alias  = "tfstates"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::TFSTATES_ACCOUNT_ID:role/admin"
  }
}
```

If all three accounts are the same (e.g., for testing), you can use the same provider:

```hcl
provider "aws" {
  region = "us-west-2"
}
```

And pass it to all three aliases:

```hcl
providers = {
  aws          = aws
  aws.cicd     = aws
  aws.tfstates = aws
}
```

## Step 4: Deploy the Module

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
}
```

## Step 5: Apply

```bash
terraform init
terraform plan
terraform apply
```

## Step 6: Verify

After deployment, check the outputs:

```bash
terraform output admin_role_arn
terraform output github_role_arn
terraform output state_manager_role_arn
```

You should see three role ARNs:

- `arn:aws:iam::PRINCIPAL_ACCOUNT:role/ih-tf-my-repo-admin`
- `arn:aws:iam::CICD_ACCOUNT:role/ih-tf-my-repo-github`
- `arn:aws:iam::TFSTATES_ACCOUNT:role/ih-tf-my-repo-state-manager`

## Step 7: Configure GitHub Actions

Use the `github_role_arn` output in your GitHub Actions workflow:

```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::CICD_ACCOUNT:role/ih-tf-my-repo-github
          aws-region: us-west-2
```

The GitHub role can then assume the admin and state-manager roles as needed during the workflow.

## Next Steps

- [Architecture](architecture.md) — understand how the three-role model works
- [Configuration Reference](configuration.md) — customize permissions and behavior
- [Examples](examples.md) — see common use cases
