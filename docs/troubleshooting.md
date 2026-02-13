# Troubleshooting

## Deployment Issues

### Error: OIDC provider not found

```
Error: no matching IAM OpenID Connect Provider found
```

**Cause**: The GitHub OIDC provider does not exist in the CI/CD account.

**Fix**: Create the OIDC provider first using the
[gh-identity-provider](https://registry.infrahouse.com/infrahouse/gh-identity-provider/aws) module:

```hcl
module "github-connector" {
  source  = "registry.infrahouse.com/infrahouse/gh-identity-provider/aws"
  version = "1.1.1"
}
```

### Error: Provider alias not configured

```
Error: missing provider "aws.cicd"
```

**Cause**: The module requires three provider aliases but one or more are missing.

**Fix**: Ensure you pass all three providers:

```hcl
module "gha" {
  providers = {
    aws          = aws           # Principal account
    aws.cicd     = aws.cicd      # CI/CD account
    aws.tfstates = aws.tfstates  # TF states account
  }
  # ...
}
```

If using a single account for all three, pass the same provider:

```hcl
providers = {
  aws          = aws
  aws.cicd     = aws
  aws.tfstates = aws
}
```

### Error: Role name too long

```
Error: expected length of name to be in the range (1 - 64)
```

**Cause**: The `repo_name` is too long. Role names are formatted as `ih-tf-{repo_name}-admin`
(and similar), and IAM role names have a 64-character limit.

**Fix**: Use a shorter `repo_name`. The prefix `ih-tf-` and suffixes like `-state-manager` add
up to 22 characters, leaving 42 characters for the repo name.

## GitHub Actions Issues

### Error: Not authorized to perform sts:AssumeRoleWithWebIdentity

```
Error: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

**Cause**: The GitHub Actions workflow's OIDC token doesn't match the trust policy on the
GitHub role. Common reasons:

1. Wrong organization or repository name in the module configuration
2. The `id-token: write` permission is missing from the workflow
3. The workflow is running from a fork

**Fix**:

1. Verify `gh_org_name` and `repo_name` match exactly (case-sensitive)
2. Add the required permission to your workflow:
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```
3. OIDC authentication does not work from forked repositories by default

### Error: Not authorized to perform sts:AssumeRole

```
Error: is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::...:role/ih-tf-...-admin
```

**Cause**: The GitHub role is trying to assume a role it's not authorized to assume.

**Fix**: Check that:

1. The admin and state-manager roles exist and their trust policies include the GitHub role
2. If assuming additional roles, they are listed in `allowed_arns`
3. If assuming roles in other accounts, consider `allow_assume_all_roles = true`

## State Management Issues

### Error: Failed to load state

```
Error: Failed to load state: AccessDenied: Access Denied
```

**Cause**: The state-manager role doesn't have access to the S3 bucket or DynamoDB table.

**Fix**:

1. Verify `state_bucket` matches the actual S3 bucket name
2. Verify `terraform_locks_table_arn` matches the actual DynamoDB table ARN
3. Ensure the state-manager role's account matches the `aws.tfstates` provider account

### Error: Error acquiring the state lock

```
Error: Error acquiring the state lock
```

**Cause**: Another Terraform process holds the lock, or a previous run crashed without
releasing it.

**Fix**:

1. Wait for the other process to finish
2. If the lock is stale, manually remove it:
   ```bash
   terraform force-unlock LOCK_ID
   ```

## Getting Help

- [Open an issue](https://github.com/infrahouse/terraform-aws-gha-admin/issues) on GitHub
- See [SECURITY.md](https://github.com/infrahouse/terraform-aws-gha-admin/blob/main/SECURITY.md)
  for reporting security vulnerabilities
- [Contact InfraHouse](https://infrahouse.com/contact) for professional support
