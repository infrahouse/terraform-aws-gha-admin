# Task: Support multi-environment colocation in gha-admin module

## Problem

The `terraform-aws-gha-admin` module creates three IAM roles (admin, github, state-manager) using only `repo_name`
for disambiguation:

- `ih-tf-{repo}-admin` → workload account
- `ih-tf-{repo}-github` → workload account
- `ih-tf-{repo}-state-manager` → shared tfstates account (`289256138624`)

The implicit assumption is one environment per AWS account. This breaks in two real cases:

1. **Shared tfstates account (structural)** — every environment writes its state-manager role into the same
   tfstates account. The second environment for a given repo fails with `EntityAlreadyExists`.
2. **Colocated workload accounts (situational)** — when two environments share a workload account (e.g.,
   lightweight dev resources hosted in the cicd/sandbox account), the admin and github roles collide too.

## Current state — PR #32

The production apply partially succeeded before failing on state-manager. Orphans to clean up:

- `493370826424`: `ih-tf-{repo}-admin` and `ih-tf-{repo}-github` from the failing env
- `289256138624`: state-manager IAM policies from the failing env
- state-manager role creation failed, so nothing to delete there

## Solution

Add a new opt-in variable `name_prefix` that disambiguates role names when set, and is a no-op when empty.

### Naming layout

Default (unchanged): `ih-tf-{repo}-{role}`
With `name_prefix = "staging"`: `ih-tf-staging-{repo}-{role}`

The disambiguator sits **left** of `{repo}` so it survives truncation to IAM's 64-char limit. `{repo}` is the
only variable-length part and is trimmed from the right when needed.

### Variable (`variables.tf`)

```hcl
variable "name_prefix" {
  description = <<-EOT
    Optional disambiguator inserted into all role names (admin, github, state-manager).
    Set this when two environments share an AWS account — most commonly when multiple
    environments write their state-manager role to the same tfstates account. Leave empty
    for the single-environment-per-account default; existing role names are preserved.
    Positioned left of repo_name so it survives truncation to IAM's 64-char limit.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.name_prefix == "" || can(regex("^[a-z0-9_-]+$", var.name_prefix))
    error_message = <<-EOT
      name_prefix must be empty or contain only lowercase letters, numbers, hyphens, and underscores.
      Got: ${var.name_prefix}
    EOT
  }
}
```

### Locals (`local.tf`)

```hcl
locals {
  # existing tags...

  name_prefix = var.name_prefix == "" ? "ih-tf-" : "ih-tf-${var.name_prefix}-"

  # Budget against the longest role suffix (-state-manager = 14 chars) so all three
  # roles share the same truncated repo segment.
  repo_budget = 64 - length(local.name_prefix) - length("-state-manager")
  repo_short  = substr(var.repo_name, 0, local.repo_budget)

  role_basename = "${local.name_prefix}${local.repo_short}"
}
```

### Role files

Replace the hardcoded names:

- `aws_iam_role.admin.tf`: `name = "${local.role_basename}-admin"`
- `aws_iam_role.github.tf`: `name = "${local.role_basename}-github"`
- `state-manager.tf`: `name = "${local.role_basename}-state-manager"`

Drop the existing `substr(..., 0, 64)` wrappers — the budget logic in `local.tf` already enforces the limit.

Audit any per-role IAM policy / instance-profile names that follow the same pattern and apply the same
treatment. Sweep `policies.tf` and `state-manager.tf` for them.

### Length precondition

Surface budget overruns at plan time rather than silently truncating:

```hcl
resource "aws_iam_role" "state_manager" {
  name = "${local.role_basename}-state-manager"
  # ...

  lifecycle {
    precondition {
      condition     = length(var.repo_name) <= local.repo_budget
      error_message = <<-EOT
        repo_name (${length(var.repo_name)} chars) exceeds budget of ${local.repo_budget} chars
        with name_prefix = "${var.name_prefix}". Either shorten repo_name or use a shorter
        name_prefix.
      EOT
    }
  }
}
```

Place it on the state-manager role since it has the longest suffix and thus the tightest budget.

## Backward compatibility

`name_prefix = ""` (the default) produces byte-identical role names to today. Existing consumers
(tinyfish, infrahouse production, anything else using gha-admin) require zero changes — no state moves,
no destroy/recreate, no plan diff.

### Why not reuse `environment`?

The module already has a required `environment` variable, but it's used only as a tag value, not in role
names. Reusing it for the role-name suffix would rename all existing roles on upgrade — exactly the
breaking change we're avoiding. Keep `environment` as the tag, add `name_prefix` as the optional
disambiguator. Related but not the same concept.

## Cleanup for PR #32

Before merging this change and re-applying:

1. In `493370826424`: delete the orphaned `ih-tf-{repo}-admin` and `ih-tf-{repo}-github` roles from the
   failing env. Production's roles in the production workload account are in a different account and
   untouched.
2. In `289256138624`: delete the orphaned state-manager IAM policies for the failing env.
3. Re-apply PR #32 with `name_prefix` set on the env that was failing.

## Testing

- Plan-only test: run `terraform plan` against an existing single-env caller with `name_prefix` unset →
  expect zero diff.
- Add a multi-env test case in `tests/` exercising `name_prefix = "staging"` and asserting all three
  role names contain the prefix in the left position.
- Negative test: assert the precondition fires when `repo_name` length exceeds the computed budget.

## README update

Add a short section under usage:

> ### Multi-environment colocation
>
> By default, role names use only `repo_name`, which assumes one environment per AWS account. When two
> environments share an AWS account — most commonly when multiple environments write to the same
> tfstates account — set `name_prefix` on each environment to disambiguate. Example:
> `name_prefix = "staging"` produces `ih-tf-staging-{repo}-admin`.

## Versioning

Minor bump (4.0.0 → 4.1.0). Not a breaking change since `name_prefix` defaults to empty.

## Out of scope

- Renaming the existing `environment` variable or changing its semantics.
- Migrating existing single-env consumers to the new naming scheme.
- Auto-detecting multi-env collisions (Terraform can't see other modules' state).
