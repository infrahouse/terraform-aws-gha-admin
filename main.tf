## IAM roles
resource "aws_iam_role" "admin" {
  name               = "ih-tf-${var.repo_name}-admin"
  description        = "Role to manage AWS account"
  assume_role_policy = data.aws_iam_policy_document.admin-trust.json
}

resource "aws_iam_role" "github" {
  name               = "ih-tf-${var.repo_name}-github"
  description        = "Role for a GitHub Actions runner in repo ${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github-trust.json
}

resource "aws_iam_role_policy_attachment" "github" {
  policy_arn = aws_iam_policy.github.arn
  role       = aws_iam_role.github.name
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = data.aws_iam_policy.admin.arn
  role       = aws_iam_role.admin.name
}
