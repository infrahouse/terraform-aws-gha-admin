## Data Sources

data "aws_iam_policy_document" "admin-assume" {
  statement {
    sid     = "000"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::990466748045:user/aleks",
        aws_iam_role.github.arn
      ]
    }
  }
  statement {
    sid     = "010"
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

data "aws_iam_policy_document" "github-assume" {
  statement {
    sid     = "010"
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
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket}/*"
    ]
  }
}

## EOF Data Sources


# IAM role

resource "aws_iam_role" "admin" {
  name               = "ih-tf-${var.repo_name}-admin"
  description        = "Role to manage AWS account"
  assume_role_policy = data.aws_iam_policy_document.admin-assume.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = data.aws_iam_policy.administrator-access.arn
  role       = aws_iam_role.admin.name
}

resource "aws_iam_role" "github" {
  name               = "ih-tf-${var.repo_name}-github"
  description        = "Role for a GitHub Actions runner in repo ${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github-assume.json
  inline_policy {
    name   = "ih-tf-${var.repo_name}-github-permissions"
    policy = data.aws_iam_policy_document.github-permissions.json
  }
}
