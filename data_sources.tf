## Data Sources
data "aws_iam_policy" "admin" {
  name = var.admin_policy_name
}

data "aws_iam_policy_document" "admin-trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = concat(
        [
          module.github_role.github_role_arn
        ],
        var.trusted_arns
      )
    }
  }

  dynamic "statement" {
    for_each = length(var.trusted_arn_patterns) > 0 ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringLike"
        variable = "aws:PrincipalArn"
        values   = var.trusted_arn_patterns
      }
    }
  }
}

data "aws_iam_policy_document" "github-permissions" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = concat(
      [
        aws_iam_role.admin.arn,
        module.state-manager.state_manager_role_arn
      ],
      var.allowed_arns
    )
  }
}

data "aws_iam_policy_document" "github-permissions-assume-all" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}
