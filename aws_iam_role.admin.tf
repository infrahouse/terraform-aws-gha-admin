resource "aws_iam_role" "admin" {
  name                 = "${local.role_basename}-admin"
  description          = "Role to manage AWS account"
  assume_role_policy   = data.aws_iam_policy_document.admin-trust.json
  max_session_duration = var.max_session_duration
  tags = merge(
    local.tags,
    {
      module_version = local.module_version
    }
  )

  lifecycle {
    precondition {
      condition     = length(var.repo_name) <= local.repo_budget
      error_message = <<-EOT
        repo_name (${length(var.repo_name)} chars) exceeds budget of
        ${local.repo_budget} chars with name_prefix = "${var.name_prefix}".
        Either shorten repo_name or use a shorter name_prefix.
      EOT
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = data.aws_iam_policy.admin.arn
  role       = aws_iam_role.admin.name
}
