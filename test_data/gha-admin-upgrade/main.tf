# tests/test_gha_admin.py::test_upgrade_keeps_github_role writes gha.tf with the module "gha" block:
# first from the registry at the previous release, then from this checkout.
resource "aws_s3_bucket" "pytest" {
  bucket_prefix = "pytest-gha-upgrade-"
}

resource "random_pet" "dynamo" {
  prefix = "pytest-gha-upgrade-"
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
