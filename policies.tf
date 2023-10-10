## IAM policies
resource "aws_iam_policy" "github" {
  provider    = aws.cicd
  name_prefix = "ih-tf-${var.repo_name}-github"
  policy      = data.aws_iam_policy_document.github-permissions.json
}
