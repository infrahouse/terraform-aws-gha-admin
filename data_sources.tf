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
          aws_iam_role.github.arn
        ],
        var.admin_allowed_arns
      )
    }
  }
}

data "aws_iam_policy_document" "github-trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        var.gh_identity_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.gh_org_name}/${var.repo_name}:*"
      ]
    }
  }
}

data "aws_iam_policy_document" "github-permissions" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.admin.arn
    ]
  }
}
