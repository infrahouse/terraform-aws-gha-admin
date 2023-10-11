## Data Sources
locals {
  gha_hostname = "token.actions.githubusercontent.com"
}

data "aws_iam_openid_connect_provider" "github" {
  provider = aws.cicd
  url      = "https://${local.gha_hostname}"
}

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
        data.aws_iam_openid_connect_provider.github.arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.gha_hostname}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "${local.gha_hostname}:sub"
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
      aws_iam_role.admin.arn,
      module.state-manager.state_manager_role_arn
    ]
  }
}
