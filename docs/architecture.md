# Architecture

## Overview

The module implements a three-role architecture across multiple AWS accounts, using GitHub OIDC
for secure, credential-less authentication.

## Multi-Account Model

![Architecture Diagram](images/architecture.svg)

## The Three Roles

### GitHub Role (`ih-tf-{repo}-github`)

- **Account**: CI/CD account
- **Trust**: GitHub OIDC provider, scoped to a specific organization and repository
- **Permissions**: Can only assume the admin and state-manager roles (plus any `allowed_arns`)
- **Purpose**: Entry point for GitHub Actions — this is the role the workflow assumes via OIDC

### Admin Role (`ih-tf-{repo}-admin`)

- **Account**: Principal account
- **Trust**: The GitHub role (and any `trusted_arns`)
- **Permissions**: Configurable via `admin_policy_name` (default: `AdministratorAccess`)
- **Purpose**: Manages AWS resources — this is the role Terraform uses to create/modify infrastructure

### State Manager Role (`ih-tf-{repo}-state-manager`)

- **Account**: TF states account
- **Trust**: The GitHub role (and any `trusted_arns`)
- **Permissions**: Read/write access to the S3 state bucket and DynamoDB lock table
- **Purpose**: Manages Terraform state — created by the
  [state-manager](https://registry.infrahouse.com/infrahouse/state-manager/aws) submodule

## Authentication Flow

1. GitHub Actions workflow requests an OIDC token from GitHub
2. The workflow calls `sts:AssumeRoleWithWebIdentity` with the token to assume the GitHub role
3. The GitHub role's trust policy validates:
    - The token comes from the GitHub OIDC provider
    - The `sub` claim matches the expected organization and repository
4. With the GitHub role credentials, the workflow assumes:
    - The **state-manager role** to read/write Terraform state
    - The **admin role** to manage AWS resources

## Security Model

- **No static credentials**: All authentication uses short-lived OIDC tokens
- **Repository-scoped**: Each repository gets its own set of roles with unique names
- **Least privilege**: The GitHub role can only assume specific roles, not perform direct AWS actions
- **Account isolation**: Roles are distributed across accounts to limit blast radius
- **Configurable admin policy**: Default is `AdministratorAccess`, but can be restricted
  to a more limited policy
