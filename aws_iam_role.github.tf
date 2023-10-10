resource "aws_iam_role" "github" {
  provider           = aws.cicd
  name               = "ih-tf-${var.repo_name}-github"
  description        = "Role for a GitHub Actions runner in repo ${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github-trust.json
}

resource "aws_iam_role_policy_attachment" "github" {
  provider   = aws.cicd
  policy_arn = aws_iam_policy.github.arn
  role       = aws_iam_role.github.name
}
