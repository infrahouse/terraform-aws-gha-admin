import sys
from subprocess import CalledProcessError

from infrahouse_toolkit.terraform import terraform_apply

from tests.conftest import TRACE_TERRAFORM, TEST_ACCOUNT, LOG


def test_gha_admin(
    ec2_client_map,
):
    tf_dir = "test_data/gha-admin"
    try:
        with terraform_apply(
            tf_dir,
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
