resource "aws_iam_role" "admin" {
  name                 = "ih-tf-${var.repo_name}-admin"
  description          = "Role to manage AWS account"
  assume_role_policy   = data.aws_iam_policy_document.admin-trust.json
  max_session_duration = var.max_session_duration
  tags = merge(
    local.tags,
    {
      module_version = local.module_version
    }
  )
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = data.aws_iam_policy.admin.arn
  role       = aws_iam_role.admin.name
}
