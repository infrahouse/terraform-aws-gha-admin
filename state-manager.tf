module "state-manager" {
  source  = "infrahouse/state-manager/aws"
  version = "1.5.0"
  providers = {
    aws = aws.tfstates
  }
  environment            = var.environment
  assuming_role_patterns = var.trusted_arn_patterns
  assuming_role_arns = concat(
    [
      aws_iam_role.github.arn
    ],
    var.trusted_arns
  )
  name                      = substr("ih-tf-${var.repo_name}-state-manager", 0, 64)
  state_bucket              = var.state_bucket
  state_key                 = var.state_key
  terraform_locks_table_arn = var.terraform_locks_table_arn
  max_session_duration      = var.max_session_duration
}
