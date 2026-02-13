# Configuration Reference

## Required Variables

### `gh_org_name`

- **Type**: `string`
- **Description**: GitHub organization name (as in `https://github.com/{gh_org_name}`)

```hcl
gh_org_name = "infrahouse"
```

### `repo_name`

- **Type**: `string`
- **Description**: Repository name in GitHub, without the organization part
  (as in `https://github.com/org/{repo_name}`)

```hcl
repo_name = "aws-control-493370826424"
```

The role names are derived from this value: `ih-tf-{repo_name}-admin`, `ih-tf-{repo_name}-github`,
`ih-tf-{repo_name}-state-manager`. Keep it short to avoid exceeding the 64-character IAM role name limit.

### `state_bucket`

- **Type**: `string`
- **Description**: Name of the S3 bucket that stores Terraform state files

```hcl
state_bucket = module.state-bucket.bucket_name
```

### `terraform_locks_table_arn`

- **Type**: `string`
- **Description**: ARN of the DynamoDB table used for Terraform state locking

```hcl
terraform_locks_table_arn = module.state-bucket.lock_table_arn
```

## Optional Variables

### `admin_policy_name`

- **Type**: `string`
- **Default**: `"AdministratorAccess"`
- **Description**: Name of the IAM managed policy to attach to the admin role.
  Change this to restrict what Terraform can do in the principal account.

```hcl
# Use a restricted policy instead of AdministratorAccess
admin_policy_name = "PowerUserAccess"
```

### `allowed_arns`

- **Type**: `list(string)`
- **Default**: `[]`
- **Description**: Additional role ARNs that the GitHub role is allowed to assume,
  beyond the admin and state-manager roles. Useful when your CI/CD workflow needs
  to assume roles in other accounts.

```hcl
allowed_arns = [
  "arn:aws:iam::111111111111:role/deploy-role",
  "arn:aws:iam::222222222222:role/deploy-role",
]
```

### `allow_assume_all_roles`

- **Type**: `bool`
- **Default**: `false`
- **Description**: If `true`, the GitHub role can assume any IAM role (not just the admin
  and state-manager). Use this for central CI/CD repositories that manage multiple accounts.

```hcl
# For a central aws-control repo that manages many accounts
allow_assume_all_roles = true
```

!!! warning
    Enabling this gives the GitHub role broad permissions. Only use it for trusted,
    central management repositories.

### `trusted_arns`

- **Type**: `list(string)`
- **Default**: `[]`
- **Description**: Additional ARNs (besides the GitHub role) that can assume the admin
  and state-manager roles. Useful for allowing human operators or other automation
  to use the same roles.

```hcl
trusted_arns = [
  "arn:aws:iam::CICD_ACCOUNT:role/admin",
]
```

### `max_session_duration`

- **Type**: `number`
- **Default**: `43200` (12 hours)
- **Description**: Maximum session duration in seconds for all three roles. The default
  of 12 hours accommodates long-running Terraform operations.

```hcl
# Reduce to 1 hour for tighter security
max_session_duration = 3600
```

## Provider Configuration

The module requires three AWS provider aliases:

```hcl
module "gha" {
  providers = {
    aws          = aws           # Principal account
    aws.cicd     = aws.cicd      # CI/CD account (GitHub OIDC provider)
    aws.tfstates = aws.tfstates  # TF states account
  }
  # ...
}
```

If all accounts are the same, pass the same provider to all three:

```hcl
providers = {
  aws          = aws
  aws.cicd     = aws
  aws.tfstates = aws
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `admin_role_arn` | ARN of the `ih-tf-{repo_name}-admin` role in the principal account |
| `github_role_arn` | ARN of the `ih-tf-{repo_name}-github` role in the CI/CD account |
| `state_manager_role_arn` | ARN of the `ih-tf-{repo_name}-state-manager` role in the TF states account |
