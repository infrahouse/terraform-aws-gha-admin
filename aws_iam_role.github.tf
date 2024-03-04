resource "aws_iam_role" "github" {
  provider           = aws.cicd
  name               = "ih-tf-${var.repo_name}-github"
  description        = "Role for a GitHub Actions runner in repo ${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github-trust.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "github" {
  provider   = aws.cicd
  policy_arn = aws_iam_policy.github.arn
  role       = aws_iam_role.github.name
}

resource "aws_iam_role_policy_attachment" "github-assume-all" {
  provider   = aws.cicd
  count      = var.allow_assume_all_roles ? 1 : 0
  policy_arn = aws_iam_policy.github-assume-all.arn
  role       = aws_iam_role.github.name
}
