module "state-manager" {
  source  = "infrahouse/state-manager/aws"
  version = "~> 0.1"
  providers = {
    aws = aws.tfstates
  }
  assuming_role_arns = [
    aws_iam_role.github.arn
  ]
  name                      = "ih-tf-${var.repo_name}-state-manager"
  state_bucket              = var.state_bucket
  terraform_locks_table_arn = var.terraform_locks_table_arn
}
