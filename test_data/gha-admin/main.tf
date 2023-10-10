resource "aws_s3_bucket" "pytest" {
  bucket_prefix = "pytest-gha-"
}

resource "random_pet" "dynamo" {
  prefix = "pytest-gha-"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = random_pet.dynamo.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}


module "gha" {
  source = "./../../"
  providers = {
    aws          = aws
    aws.cicd     = aws
    aws.tfstates = aws
  }
  gh_org_name               = var.gh_org_name
  repo_name                 = var.repo_name
  state_bucket              = aws_s3_bucket.pytest.bucket
  terraform_locks_table_arn = aws_dynamodb_table.terraform_locks.arn
}
