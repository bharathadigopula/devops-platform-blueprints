<!--
==============================================================================
GITHUB ENVIRONMENT SETUP
==============================================================================
-->

# GitHub Environment Setup

This repo uses GitHub Environments to separate deployment settings for `dev`, `stage`, and `prod`.

GitHub environment variables are read in workflows through the `vars` context.

Official GitHub references:

- https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment
- https://docs.github.com/actions/learn-github-actions/variables

## Required Environments

<!--
==============================================================================
REQUIRED ENVIRONMENTS
==============================================================================
-->

Create these GitHub Environments:

```text
dev
stage
prod
```

Use required reviewers for `stage` and `prod`.

For `dev`, required reviewer is optional.

## Required Variables

<!--
==============================================================================
REQUIRED ENVIRONMENT VARIABLES
==============================================================================
-->

Each environment needs these variables:

| Variable | Value Source | Used By |
| --- | --- | --- |
| `AWS_ROLE_TO_ASSUME` | `github_actions_role_arn` output from `00-identity-bootstrap` | State backend, plan, deploy |
| `TF_BACKEND_BUCKET` | `state_bucket_name` output from `00-state-backend` | Plan, deploy |
| `TF_BACKEND_DYNAMODB_TABLE` | `lock_table_name` output from `00-state-backend` | Plan, deploy |
| `TF_BACKEND_KMS_KEY_ARN` | `state_kms_key_arn` output from `00-state-backend` | Plan, deploy |

These values are configuration variables, not secrets.

Do not store AWS access keys in this repo.

## Create Environments

<!--
==============================================================================
CREATE GITHUB ENVIRONMENTS
==============================================================================
-->

1. Open the GitHub repo.
2. Go to `Settings`.
3. Go to `Environments`.
4. Select `New environment`.
5. Create `dev`.
6. Repeat for `stage`.
7. Repeat for `prod`.
8. Add required reviewers where needed.

## Create Environment Variables

<!--
==============================================================================
CREATE ENVIRONMENT VARIABLES
==============================================================================
-->

For each environment:

1. Open the GitHub repo.
2. Go to `Settings`.
3. Go to `Environments`.
4. Select the environment.
5. Go to `Environment variables`.
6. Select `Add variable`.
7. Enter the variable name.
8. Enter the variable value.
9. Select `Add variable`.

Repeat until all required variables exist.

## Bootstrap Order

<!--
==============================================================================
BOOTSTRAP ORDER
==============================================================================
-->

Run the setup in this order:

1. Apply `blueprints/aws-ecs-fargate-github-oidc/infrastructure/00-identity-bootstrap`.
2. Copy the `github_actions_role_arn` output.
3. Review the `blueprint_permissions_policy_arn` output.
4. Create `AWS_ROLE_TO_ASSUME` in the `dev` environment.
5. Run `AWS ECS Fargate OIDC State Backend` with `action=apply`.
6. Copy the state backend outputs.
7. Create backend variables in `dev`, `stage`, and `prod`.
8. Create `AWS_ROLE_TO_ASSUME` in `stage` and `prod`.
9. Run `AWS ECS Fargate OIDC Plan`.
10. Review the plan.
11. Run `AWS ECS Fargate OIDC Deploy`.

## Local Output Commands

<!--
==============================================================================
LOCAL OUTPUT COMMANDS
==============================================================================
-->

After applying identity bootstrap locally:

```bash
cd blueprints/aws-ecs-fargate-github-oidc/infrastructure/00-identity-bootstrap
terraform output -raw github_actions_role_arn
terraform output -raw blueprint_permissions_policy_arn
```

After applying state backend locally:

```bash
cd blueprints/aws-ecs-fargate-github-oidc/infrastructure/00-state-backend
terraform output -raw state_bucket_name
terraform output -raw lock_table_name
terraform output -raw state_kms_key_arn
```

## Expected Variable Values

<!--
==============================================================================
EXPECTED VARIABLE VALUES
==============================================================================
-->

Example value shapes:

```text
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/ecs-fargate-oidc-dev-github-actions
TF_BACKEND_BUCKET=ecs-fargate-oidc-platform-tfstate-<account-id>-us-east-1
TF_BACKEND_DYNAMODB_TABLE=ecs-fargate-oidc-platform-terraform-locks
TF_BACKEND_KMS_KEY_ARN=arn:aws:kms:us-east-1:<account-id>:key/<key-id>
```

## Workflow Usage

<!--
==============================================================================
WORKFLOW USAGE
==============================================================================
-->

`AWS ECS Fargate OIDC State Backend` uses:

```text
AWS_ROLE_TO_ASSUME
```

`AWS ECS Fargate OIDC Plan` uses:

```text
AWS_ROLE_TO_ASSUME
TF_BACKEND_BUCKET
TF_BACKEND_DYNAMODB_TABLE
TF_BACKEND_KMS_KEY_ARN
```

`AWS ECS Fargate OIDC Deploy` uses:

```text
AWS_ROLE_TO_ASSUME
TF_BACKEND_BUCKET
TF_BACKEND_DYNAMODB_TABLE
TF_BACKEND_KMS_KEY_ARN
```

`AWS ECS Fargate OIDC Destroy` uses:

```text
AWS_ROLE_TO_ASSUME
TF_BACKEND_BUCKET
TF_BACKEND_DYNAMODB_TABLE
TF_BACKEND_KMS_KEY_ARN
```

## Destroy Workflow

<!--
==============================================================================
DESTROY WORKFLOW
==============================================================================
-->

Use the destroy workflow after testing a live environment.

Run:

```text
Actions -> AWS ECS Fargate OIDC Destroy -> Run workflow
```

Use this confirmation phrase:

```text
destroy-aws-ecs-fargate-github-oidc
```

The destroy workflow removes workload resources only.

Keep the state backend until all environments have been removed and state has been reviewed.
