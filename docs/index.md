# terraform-aws-gha-admin

A Terraform module that creates IAM roles for GitHub Actions CI/CD in a multi-account AWS environment
using OpenID Connect (OIDC) authentication.

## Overview

This module creates three IAM roles across multiple AWS accounts to enable secure GitHub Actions
CI/CD for Terraform-managed infrastructure:

- **Admin role** (`ih-tf-{repo_name}-admin`) — manages AWS resources in the principal account
- **GitHub role** (`ih-tf-{repo_name}-github`) — assumed by GitHub Actions via OIDC in the CI/CD account
- **State Manager role** (`ih-tf-{repo_name}-state-manager`) — manages Terraform state access in the TF states account

![Architecture Diagram](images/architecture.svg)

## Features

- **No long-lived credentials** — uses GitHub OIDC for authentication
- **Multi-account architecture** — proper separation of CI/CD, principal, and state accounts
- **Least privilege** — GitHub Actions can only assume specific, scoped roles
- **Configurable permissions** — choose the admin policy or provide your own
- **State management included** — automatic Terraform state access via the state-manager submodule
- **Assume-all mode** — optional ability for central CI/CD repos to assume any role

## Quick Start

```hcl
module "gha" {
  source  = "registry.infrahouse.com/infrahouse/gha-admin/aws"
  version = "3.6.1"
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

## Requirements

| Name | Version |
|------|---------|
| Terraform | ~> 1.5 |
| AWS Provider | >= 5.11, < 7.0 |

## Getting Help

- [Getting Started Guide](getting-started.md) — first deployment walkthrough
- [Architecture](architecture.md) — how the three-role model works
- [Configuration Reference](configuration.md) — all variables explained
- [Examples](examples.md) — common use cases
- [Troubleshooting](troubleshooting.md) — common issues and solutions
- [Changelog](changelog.md) — version history

## Links

- [GitHub Repository](https://github.com/infrahouse/terraform-aws-gha-admin)
- [Terraform Registry](https://registry.infrahouse.com/infrahouse/gha-admin/aws)
- [Report Issues](https://github.com/infrahouse/terraform-aws-gha-admin/issues)
