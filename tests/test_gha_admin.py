import json
import sys
from os import path as osp
from subprocess import CalledProcessError, run

import pytest
from pytest_infrahouse import terraform_apply

from tests.conftest import (
    TRACE_TERRAFORM,
    TEST_ACCOUNT,
    LOG,
    TERRAFORM_ROOT_DIR,
    assert_github_trust,
    update_terraform_tf,
    cleanup_dot_terraform,
    write_gha_module,
)

# The last release that created the GitHub role itself instead of through the github-role module.
PREVIOUS_RELEASE = "4.1.0"
REGISTRY_SOURCE = "registry.infrahouse.com/infrahouse/gha-admin/aws"


@pytest.mark.parametrize(
    "aws_provider_version",
    ["~> 5.11", "~> 6.0"],
    ids=["aws-5", "aws-6"],
)
def test_gha_admin(
    ec2_client_map,
    iam_client,
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
            assert (
                tf_out["state_manager_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-foo-repo-state-manager"
            )
            assert_github_trust(
                iam_client, "ih-tf-foo-repo-github", "foo-org", "foo-repo"
            )
    except CalledProcessError as err:
        LOG.error(err)
        LOG.info("STDOUT: %s", err.stdout)
        LOG.error("STDERR: %s", err.stderr)
        if TRACE_TERRAFORM:
            LOG.info("Check output in files tf-apply-trace.txt, tf-destroy-trace.txt.")
        sys.exit(1)


@pytest.mark.parametrize(
    "aws_provider_version",
    ["~> 5.11", "~> 6.0"],
    ids=["aws-5", "aws-6"],
)
def test_gha_admin_name_prefix(
    ec2_client_map,
    iam_client,
    aws_provider_version,
):
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "gha-admin")
    cleanup_dot_terraform(terraform_module_dir)
    update_terraform_tf(terraform_module_dir, aws_provider_version)
    try:
        with terraform_apply(
            terraform_module_dir,
            json_output=True,
            var_file="terraform-prefix.tfvars",
            enable_trace=TRACE_TERRAFORM,
        ) as tf_out:
            assert (
                tf_out["admin_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-staging-foo-repo-admin"
            )
            assert (
                tf_out["github_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-staging-foo-repo-github"
            )
            assert (
                tf_out["state_manager_role_arn"]["value"]
                == f"arn:aws:iam::{TEST_ACCOUNT}:role/ih-tf-staging-foo-repo-state-manager"
            )
            assert_github_trust(
                iam_client, "ih-tf-staging-foo-repo-github", "foo-org", "foo-repo"
            )
    except CalledProcessError as err:
        LOG.error(err)
        LOG.info("STDOUT: %s", err.stdout)
        LOG.error("STDERR: %s", err.stderr)
        if TRACE_TERRAFORM:
            LOG.info("Check output in files tf-apply-trace.txt, tf-destroy-trace.txt.")
        sys.exit(1)


@pytest.mark.parametrize(
    "aws_provider_version",
    ["~> 5.11", "~> 6.0"],
    ids=["aws-5", "aws-6"],
)
def test_upgrade_keeps_github_role(
    ec2_client_map,
    iam_client,
    aws_provider_version: str,
) -> None:
    """
    Upgrading from the previous release moves the GitHub role into the github-role module
    and updates it in place: no resource is created or destroyed, and the role then trusts
    the immutable OIDC subject claim too.
    """
    terraform_module_dir = osp.join(TERRAFORM_ROOT_DIR, "gha-admin-upgrade")
    cleanup_dot_terraform(terraform_module_dir)
    update_terraform_tf(terraform_module_dir, aws_provider_version)
    write_gha_module(terraform_module_dir, REGISTRY_SOURCE, PREVIOUS_RELEASE)
    try:
        with terraform_apply(
            terraform_module_dir,
            json_output=True,
            var_file="terraform.tfvars",
            enable_trace=TRACE_TERRAFORM,
        ) as tf_out:
            role_name = tf_out["github_role_arn"]["value"].split("/")[-1]

            write_gha_module(terraform_module_dir, "./../../")
            plan = plan_upgrade(terraform_module_dir)
            changes = {
                change["address"]: change
                for change in plan["resource_changes"]
                if change["mode"] == "managed"
            }
            created_or_destroyed = [
                address
                for address, change in changes.items()
                if {"create", "delete"} & set(change["change"]["actions"])
            ]
            assert created_or_destroyed == []

            github_role = changes["module.gha.module.github_role.aws_iam_role.github"]
            assert github_role["previous_address"] == "module.gha.aws_iam_role.github"
            assert github_role["change"]["actions"] == ["update"]

            run(
                ["terraform", "apply", "-input=false", "-no-color", "upgrade.tfplan"],
                cwd=terraform_module_dir,
                check=True,
            )
            assert_github_trust(iam_client, role_name, "foo-org", "foo-upgrade")
    except CalledProcessError as err:
        LOG.error(err)
        LOG.info("STDOUT: %s", err.stdout)
        LOG.error("STDERR: %s", err.stderr)
        if TRACE_TERRAFORM:
            LOG.info("Check output in files tf-apply-trace.txt, tf-destroy-trace.txt.")
        sys.exit(1)


def plan_upgrade(terraform_module_dir: str) -> dict:
    """
    Re-initialize after the module source changed, save the plan to upgrade.tfplan
    and return it as JSON.

    :param terraform_module_dir: Directory of the test root module.
    :return: Output of ``terraform show -json`` for the saved plan.
    """
    for cmd in [
        ["terraform", "init", "-input=false", "-no-color"],
        [
            "terraform",
            "plan",
            "-var-file=terraform.tfvars",
            "-input=false",
            "-no-color",
            "-out=upgrade.tfplan",
        ],
    ]:
        run(cmd, cwd=terraform_module_dir, check=True)
    shown = run(
        ["terraform", "show", "-json", "upgrade.tfplan"],
        cwd=terraform_module_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(shown.stdout)
