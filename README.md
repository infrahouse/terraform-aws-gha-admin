# Module terraform-aws-gha-admin

The module creates two IAM roles:
* `ih-tf-{var.repo_name}-admin` - the role that has permissions to manage AWS resources.
* `ih-tf-{var.repo_name}-github` - the role can upload/download Terraform Plan files to a state bucket.
It also can assume the `ih-tf-{var.repo_name}-admin` role.

In the Terraform CI/CD context in GitHub Actions it's optimal to work with two roles.
One role is a `*-github` role. A GitHub Actions worker assume this role. The role allows
to upload/download/delete a Terraform Plan file. The `*-github` role also assume the `*-admin` role
that is used by Terraform for the `plan` and `apply` stages.
It's up to a module user to decide what the `*-admin` role can do.
By default, it will have the `AdministratorAccess` policy attached, but you might want to pass a limited
policy accordingly to your security practices.

The module requires a GitHub OpenID connector to be created. The [gh-identity-provider
](https://registry.terraform.io/modules/infrahouse/gh-identity-provider/aws/latest) module can do it for you.

## Usage

Make sure the GitHub connector is created. It's the pre-requisite.
```hcl
module "github-connector" {
  source  = "infrahouse/gh-identity-provider/aws"
  version = "~> 1.0"
}
```
Now create the roles for GitHub Actions.
```hcl
module "ih-tf-aws-control-493370826424-admin" {
  source = "infrahouse/gha-admin/aws"
  version = "~> 1.0"
  gh_identity_provider_arn = module.github-connector.gh_openid_connect_provider_arn
  gh_org_name              = "infrahouse"
  repo_name                = "aws-control-493370826424"
  state_bucket             = "infrahouse-aws-control-493370826424"
}
```
* `gh_org_name` is `infrahouse` as in https://github.com/infrahouse.
* `repo_name` is `aws-control-493370826424` as in https://github.com/infrahouse/aws-control-493370826424.
* `aws-control-493370826424` is a Terraform root module, so it creates actual resources and stores a Terraform state
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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.admin-assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github-assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_allowed_arns"></a> [admin\_allowed\_arns](#input\_admin\_allowed\_arns) | A list of ARNs besides `ih-tf-{var.repo_name}-github` that are allowed to assume the `ih-tf-{var.repo_name}-admin` role. | `list(string)` | `[]` | no |
| <a name="input_admin_policy_name"></a> [admin\_policy\_name](#input\_admin\_policy\_name) | Name of the IAM policy the `ih-tf-{var.repo_name}-admin` role will have. This is what the role can do. | `string` | `"AdministratorAccess"` | no |
| <a name="input_gh_identity_provider_arn"></a> [gh\_identity\_provider\_arn](#input\_gh\_identity\_provider\_arn) | GitHub OpenID identity provider. See https://registry.terraform.io/modules/infrahouse/gh-identity-provider/aws/latest. | `any` | n/a | yes |
| <a name="input_gh_org_name"></a> [gh\_org\_name](#input\_gh\_org\_name) | GitHub organization name. | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Repository name in GitHub. Without the organization part. | `any` | n/a | yes |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | Name of the S3 bucket with the state. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_role_arn"></a> [admin\_role\_arn](#output\_admin\_role\_arn) | ARN of the `ih-tf-{var.repo_name}-admin` role |
| <a name="output_github_role_arn"></a> [github\_role\_arn](#output\_github\_role\_arn) | ARN of the `ih-tf-{var.repo_name}-github` role |
