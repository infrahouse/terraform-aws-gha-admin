# The github-role module owns the OIDC trust policy, so fixes to it land here with a version bump. 1.5.0 accepts
# GitHub's immutable subject claims, mandatory since 2026-07-15 for repositories created, renamed or transferred.
module "github_role" {
  source  = "registry.infrahouse.com/infrahouse/github-role/aws"
  version = "1.5.0"
  providers = {
    aws = aws.cicd
  }
  gh_org_name          = var.gh_org_name
  repo_name            = var.repo_name
  role_name            = "${local.role_basename}-github"
  max_session_duration = var.max_session_duration
}

# Up to 4.1.0 this module created the role itself. The move keeps the existing role:
# the name is unchanged, so the trust policy and tags are updated in place instead of replacing it.
moved {
  from = aws_iam_role.github
  to   = module.github_role.aws_iam_role.github
}

resource "aws_iam_role_policy_attachment" "github" {
  provider   = aws.cicd
  policy_arn = aws_iam_policy.github.arn
  role       = module.github_role.github_role_name
}

resource "aws_iam_role_policy_attachment" "github-assume-all" {
  provider   = aws.cicd
  count      = var.allow_assume_all_roles ? 1 : 0
  policy_arn = aws_iam_policy.github-assume-all[0].arn
  role       = module.github_role.github_role_name
}
