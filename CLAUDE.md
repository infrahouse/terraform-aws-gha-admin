# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## First Steps

**Your first tool call in this repository MUST be reading .claude/CODING_STANDARD.md.
Do not read any other files, search, or take any actions until you have read it.**
This contains InfraHouse's comprehensive coding standards for Terraform, Python, and general formatting rules.

## Project Overview

**terraform-aws-gha-admin** is a Terraform module that creates three IAM roles for GitHub Actions CI/CD across a multi-account AWS environment:

1. **Admin role** (`ih-tf-{repo_name}-admin`) — in the principal account, manages AWS resources (default: AdministratorAccess)
2. **GitHub role** (`ih-tf-{repo_name}-github`) — in the CI/CD account, assumed by GitHub Actions via OIDC, can only assume the admin and state-manager roles
3. **State manager role** (`ih-tf-{repo_name}-state-manager`) — in the TF states account, manages Terraform state S3/DynamoDB access (created by the `state-manager` submodule)

The module uses GitHub OpenID Connect (OIDC) for authentication — no long-lived AWS credentials.

## Build Commands

```bash
make bootstrap       # Install Python dependencies (pip)
make install-hooks   # Symlink git hooks from hooks/ into .git/hooks/
make format          # terraform fmt -recursive && black tests
make lint            # terraform fmt --check -recursive
make test            # pytest -xvvs tests
make clean           # Remove .terraform, state files, caches
```

To run a single test: `pytest -xvvs tests/test_gha_admin.py`

## Architecture

### Multi-provider setup

The module requires three AWS provider aliases configured in `terraform.tf`:
- `aws` — principal account
- `aws.cicd` — CI/CD account (GitHub OIDC provider lives here)
- `aws.tfstates` — passed through to the `state-manager` submodule

### Key Terraform files

| File | Purpose |
|------|---------|
| `aws_iam_role.admin.tf` | Admin role + trust policy in principal account |
| `aws_iam_role.github.tf` | GitHub Actions role + OIDC trust in CI/CD account |
| `policies.tf` | IAM policies for the GitHub role (assume specific roles, or assume all) |
| `data_sources.tf` | Policy documents and OIDC provider data source |
| `state-manager.tf` | Invokes `infrahouse/state-manager/aws` v1.3.0 |
| `local.tf` | Common tags |
| `variables.tf` | All input variables |
| `outputs.tf` | admin_role_arn, github_role_arn, state_manager_role_arn |

### Testing

Tests in `tests/` use `infrahouse_toolkit.terraform.terraform_apply` to deploy real AWS infrastructure into test account `303467602807`. The test fixture in `test_data/gha-admin/` contains a complete Terraform root module that calls this module. Tests assume the role `arn:aws:iam::303467602807:role/gha-admin-tester` via STS.

### CI/CD workflows (`.github/workflows/`)

- `terraform-review.yml` — PR validation (fmt, validate, checkov, module review)
- `terraform-CD.yml` — publishes module to `registry.infrahouse.com` on version tags
- `checkov.yml` — IaC security scanning
- `release.yml` — GitHub release + changelog via git-cliff
- `docs.yml` — MkDocs to GitHub Pages
- `vuln-scanner-pr.yml` — dependency vulnerability scanning

### Commit conventions

A `commit-msg` hook (from `hooks/commit-msg`) enforces Conventional Commits format. Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `security`. Run `make install-hooks` to activate.
