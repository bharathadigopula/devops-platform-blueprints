<!--
==============================================================================
AWS ECS FARGATE GITHUB OIDC README
==============================================================================
-->

# AWS ECS Fargate With GitHub OIDC

This blueprint deploys a small containerized service to AWS ECS Fargate.

The workload runs in private subnets behind a public Application Load Balancer.

GitHub Actions uses AWS OIDC instead of static AWS access keys.

## What This Shows

<!--
==============================================================================
BLUEPRINT CAPABILITIES
==============================================================================
-->

- Public ALB with private workload
- ECS Fargate service deployment
- ECR image publishing
- GitHub Actions OIDC trust
- Terraform validation and planning
- Manual apply with explicit confirmation
- Deployment circuit breaker rollback
- CloudWatch application logs
- Cost and ownership tags

## Structure

<!--
==============================================================================
BLUEPRINT STRUCTURE
==============================================================================
-->

| Path | Purpose |
| --- | --- |
| `app` | Small Node.js HTTP service |
| `infrastructure/bootstrap` | One-time GitHub OIDC role setup |
| `infrastructure/workload` | ECS, ALB, VPC, ECR, IAM, and logs |

## Deployment Notes

<!--
==============================================================================
DEPLOYMENT NOTES
==============================================================================
-->

The workload uses private subnets.

For a live deployment, private tasks need outbound access to ECR and CloudWatch Logs.

Set `enable_nat_gateway = true` for the simplest live setup, or adapt the blueprint to use VPC endpoints.

NAT Gateway has hourly and data processing costs.

## Manual Flow

<!--
==============================================================================
MANUAL DEPLOYMENT FLOW
==============================================================================
-->

1. Run `terraform init` and `terraform apply` in `infrastructure/bootstrap`.
2. Add the output role ARN as the GitHub repository variable `AWS_ROLE_TO_ASSUME`.
3. Attach account-specific permissions to the OIDC role through `managed_policy_arns` or your own IAM process.
4. Run the validation workflow.
5. Run the deploy workflow with the required confirmation phrase.
