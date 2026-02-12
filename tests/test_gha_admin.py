import sys
from os import path as osp
from subprocess import CalledProcessError

import pytest
from pytest_infrahouse import terraform_apply

from tests.conftest import (
    TRACE_TERRAFORM,
    TEST_ACCOUNT,
    LOG,
    TERRAFORM_ROOT_DIR,
    update_terraform_tf,
    cleanup_dot_terraform,
)


@pytest.mark.parametrize(
    "aws_provider_version",
    ["~> 5.11", "~> 6.0"],
    ids=["aws-5", "aws-6"],
)
def test_gha_admin(
    ec2_client_map,
    aws_provider_version,
):
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "gha-admin")
    cleanup_dot_terraform(terraform_module_dir)
    update_terraform_tf(terraform_module_dir, aws_provider_version)
    try:
        with terraform_apply(
            terraform_module_dir,
            json_output=True,
            var_file="terraform.tfvars",
            enable_trace=TRACE_TERRAFORM,
        ) as tf_out:
            assert (
                tf_out["admin_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-foo-repo-admin"
            )
            assert (
                tf_out["github_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-foo-repo-github"
            )
    except CalledProcessError as err:
        LOG.error(err)
        LOG.info("STDOUT: %s", err.stdout)
        LOG.error("STDERR: %s", err.stderr)
        if TRACE_TERRAFORM:
            LOG.info("Check output in files tf-apply-trace.txt, tf-destroy-trace.txt.")
        sys.exit(1)
