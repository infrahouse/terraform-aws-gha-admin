## IAM policies
resource "aws_iam_policy" "github" {
  name = "ih-tf-${var.repo_name}-github"
  policy = data.aws_iam_policy_document.github-permissions.json
}
