import logging
import shutil
from contextlib import contextmanager
from os import path as osp, remove
from typing import Optional

from textwrap import dedent

from infrahouse_core.logging import setup_logging

# "303467602807" is our test account
TEST_ACCOUNT = "303467602807"
TEST_ROLE_ARN = "arn:aws:iam::303467602807:role/gha-admin-tester"
DEFAULT_PROGRESS_INTERVAL = 10
TRACE_TERRAFORM = False


LOG = logging.getLogger(__name__)
setup_logging(LOG, debug=True)


TERRAFORM_ROOT_DIR = osp.join(osp.dirname(__file__), "..", "test_data")


def update_source(path, module_path):
    lines = open(path).readlines()
    with open(path, "w") as fp:
        for line in lines:
            line = line.replace("%SOURCE%", module_path)
            fp.write(line)


def update_terraform_tf(terraform_module_dir, aws_provider_version):
    terraform_tf_path = osp.join(terraform_module_dir, "terraform.tf")
    with open(terraform_tf_path, "w") as fp:
        fp.write(
            dedent(
                f"""\
                terraform {{
                  required_providers {{
                    aws = {{
                      source  = "hashicorp/aws"
                      version = "{aws_provider_version}"
                    }}
                  }}
                }}
                """
            )
        )


def write_gha_module(
    terraform_module_dir: str, source: str, version: Optional[str] = None
) -> None:
    """
    Write gha.tf with the ``module "gha"`` block that the upgrade test switches between versions.

    :param terraform_module_dir: Directory of the test root module.
    :param source: Module source: a registry address or a local path.
    :param version: Exact module version for a registry source. None for a local path.
    """
    # Laid out the way terraform fmt would, so that make lint passes after a local test run.
    source_lines = (
        f'source  = "{source}"\n                  version = "{version}"'
        if version
        else f'source = "{source}"'
    )
    with open(osp.join(terraform_module_dir, "gha.tf"), "w") as fp:
        fp.write(
            dedent(
                f"""\
                module "gha" {{
                  {source_lines}
                  providers = {{
                    aws          = aws
                    aws.cicd     = aws
                    aws.tfstates = aws
                  }}
                  environment               = var.environment
                  gh_org_name               = var.gh_org_name
                  repo_name                 = var.repo_name
                  state_bucket              = aws_s3_bucket.pytest.bucket
                  terraform_locks_table_arn = aws_dynamodb_table.terraform_locks.arn
                }}
                """
            )
        )


def assert_github_trust(
    iam_client, role_name: str, gh_org_name: str, repo_name: str
) -> None:
    """
    Check that the GitHub role trusts both forms of the repository's OIDC subject claim:
    the legacy ``repo:org/repo:*`` and the immutable ``repo:org@<id>/repo@<id>:*``.

    :param iam_client: boto3 IAM client.
    :param role_name: Name of the GitHub role.
    :param gh_org_name: GitHub organization name.
    :param repo_name: Repository name.
    """
    statement = iam_client.get_role(RoleName=role_name)["Role"][
        "AssumeRolePolicyDocument"
    ]["Statement"][0]
    subjects = statement["Condition"]["StringLike"][
        "token.actions.githubusercontent.com:sub"
    ]
    assert sorted(subjects) == sorted(
        [
            f"repo:{gh_org_name}/{repo_name}:*",
            f"repo:{gh_org_name}@*/{repo_name}@*:*",
        ]
    )


def cleanup_dot_terraform(terraform_module_dir):
    state_files = [
        osp.join(terraform_module_dir, ".terraform"),
        osp.join(terraform_module_dir, ".terraform.lock.hcl"),
    ]
    for state_file in state_files:
        try:
            if osp.isdir(state_file):
                shutil.rmtree(state_file)
            elif osp.isfile(state_file):
                remove(state_file)
        except FileNotFoundError:
            pass


@contextmanager
def create_tf_conf(tf_dir, region, management_cidr_block, vpc_cidr_block, subnets):
    config_file = osp.join(tf_dir, "terraform.tfvars")
    try:
        with open(config_file, "w") as fd:
            fd.write(
                dedent(
                    f"""
                    region = "{region}"
                    management_cidr_block = "{management_cidr_block}"
                    vpc_cidr_block = "{vpc_cidr_block}"
                    """
                )
            )
            fd.write(f"subnets = {subnets}")
        LOG.info(
            "Terraform configuration: %s",
            open(osp.join(tf_dir, "terraform.tfvars")).read(),
        )
        yield
    finally:
        pass
        # os.remove(config_file)
