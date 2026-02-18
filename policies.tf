## IAM policies
resource "aws_iam_policy" "github" {
  provider    = aws.cicd
  name_prefix = "ih-tf-${var.repo_name}-github"
  policy      = data.aws_iam_policy_document.github-permissions.json
  tags        = local.tags
}

resource "aws_iam_policy" "github-assume-all" {
  count       = var.allow_assume_all_roles ? 1 : 0
  provider    = aws.cicd
  name_prefix = "ih-tf-${var.repo_name}-github-assume-all"
  policy      = data.aws_iam_policy_document.github-permissions-assume-all.json
  tags        = local.tags
}
