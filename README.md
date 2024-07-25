# Module terraform-aws-gha-admin

## IAM Roles for Terraform CI/CD

There are three IAM roles in the multi-account environment used by the CI/CD system.  

![IAM Roles for Terraform CI/CD](https://raw.githubusercontent.com/infrahouse/terraform-aws-gha-admin/main/assets/IAM_Roles_for_Terraform_CI_CD.png)

## AWS accounts

* `aws.cicd` - account for CI/CD components.
* `aws.tfstates` - account for Terraform state buckets, a DynamoDB lock table, and IAM roles to manage the states.
* `aws` - a principal account under the Terraform management.

## IAM Roles

The module creates three IAM roles:

* `ih-tf-{var.repo_name}-admin` - the role that has permissions to manage AWS resources. 
  The role is created in the "principal" AWS account.
* `ih-tf-{var.repo_name}-state-manager` - the role can upload/download a Terraform state. 
  The role is created in the "TF states" account by 
  the [state-manager](https://registry.terraform.io/modules/infrahouse/state-manager/aws/latest) module.
* `ih-tf-{var.repo_name}-github` - the role can only assume the `ih-tf-{var.repo_name}-admin`,
  `ih-tf-{var.repo_name}-state-manager`, and `var.allowed_arns` role.
  The role is created in the CD/CD account.

It's up to a module user to decide what the `*-admin` role can do.
By default, it will have the `AdministratorAccess` policy attached, but you might want to pass a limited
policy accordingly to your security practices.

The module requires a GitHub OpenID connector to be created. The [gh-identity-provider
](https://registry.terraform.io/modules/infrahouse/gh-identity-provider/aws/latest) module can do it for you.

## Usage

### Pre-requisites

Make sure the GitHub connector is created. The GitHub OpenID connector
must be created in the CI/CD account, where the "*-github" role is.

```hcl
module "github-connector" {
  source  = "registry.infrahouse.com/infrahouse/gh-identity-provider/aws"
  version = "~> 1.0"
}
```

A Terraform state bucket. You can use
 the [state-bucket](https://registry.terraform.io/modules/infrahouse/state-bucket/aws/latest) module.

The module will create the S3 state bucket and DynamoDB table for the state lock
 following recommendations outlined by
 [Hashicorp](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
 and [Gruntwork](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa).

```hcl
module "state-bucket" {
  source  = "registry.infrahouse.com/infrahouse/state-bucket/aws"
  version = "~> 2.0"
  providers = {
    aws = aws.tf-states
  }
  bucket = "infrahouse-aws-control-493370826424"
}
```

### gha-admin module

Now, create the roles for GitHub Actions. Note that module requires three providers.
 Each of them is supposed to describe different AWS accounts.

```hcl
module "gha" {
  providers = {
    aws          = aws
    aws.cicd     = aws.your-cicd-provider
    aws.tfstates = aws.your-tf-states-provider
  }
  source                    = "registry.infrahouse.com/infrahouse/gha-admin/aws"
  version                   = "~> 3.4"
  gh_org_name               = "infrahouse"
  repo_name                 = "aws-control-493370826424"
  state_bucket              = module.state-bucket.bucket_name
  terraform_locks_table_arn = module.state-bucket.lock_table_arn
}
```

* `gh_org_name` is `infrahouse` as in https://github.com/infrahouse.
* `repo_name` is `aws-control-493370826424` as in https://github.com/infrahouse/aws-control-493370826424.
* `gha` is a Terraform root module, so it creates actual resources and stores a Terraform state
in `state_bucket` which is `s3://infrahouse-aws-control-493370826424`.
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.11 |
| <a name="provider_aws.cicd"></a> [aws.cicd](#provider\_aws.cicd) | ~> 5.11 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_state-manager"></a> [state-manager](#module\_state-manager) | infrahouse/state-manager/aws | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github-assume-all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github-assume-all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.admin-trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github-permissions-assume-all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github-trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_policy_name"></a> [admin\_policy\_name](#input\_admin\_policy\_name) | Name of the IAM policy the `ih-tf-{var.repo_name}-admin` role will have. This is what the role can do. | `string` | `"AdministratorAccess"` | no |
| <a name="input_allow_assume_all_roles"></a> [allow\_assume\_all\_roles](#input\_allow\_assume\_all\_roles) | If true the -github role may assume all possible roles. | `bool` | `false` | no |
| <a name="input_allowed_arns"></a> [allowed\_arns](#input\_allowed\_arns) | A list of ARNs `ih-tf-{var.repo_name}-github` is allowed to assume besides `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` roles. | `list(string)` | `[]` | no |
| <a name="input_gh_org_name"></a> [gh\_org\_name](#input\_gh\_org\_name) | GitHub organization name. | `string` | n/a | yes |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration (in seconds) that you want to set for the specified role. | `number` | `43200` | no |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Repository name in GitHub. Without the organization part. | `any` | n/a | yes |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | Name of the S3 bucket with the state | `any` | n/a | yes |
| <a name="input_terraform_locks_table_arn"></a> [terraform\_locks\_table\_arn](#input\_terraform\_locks\_table\_arn) | DynamoDB table that holds Terraform state locks. | `any` | n/a | yes |
| <a name="input_trusted_arns"></a> [trusted\_arns](#input\_trusted\_arns) | A list of ARNs besides `ih-tf-{var.repo_name}-github` that are allowed to assume the `ih-tf-{var.repo_name}-admin` and `ih-tf-{var.repo_name}-state-manager` role. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_role_arn"></a> [admin\_role\_arn](#output\_admin\_role\_arn) | ARN of the `ih-tf-{var.repo_name}-admin` role |
| <a name="output_github_role_arn"></a> [github\_role\_arn](#output\_github\_role\_arn) | ARN of the `ih-tf-{var.repo_name}-github` role |
| <a name="output_state_manager_role_arn"></a> [state\_manager\_role\_arn](#output\_state\_manager\_role\_arn) | ARN of the `ih-tf-{var.repo_name}-state-manager` role |
