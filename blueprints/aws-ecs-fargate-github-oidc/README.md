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
- Private ECR, CloudWatch Logs, and S3 access through VPC endpoints
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
| `infrastructure/00-identity-bootstrap` | One-time GitHub OIDC role setup |
| `infrastructure/modules/ecs-fargate-platform` | Shared ECS platform implementation |
| `infrastructure/environments/dev` | Deployable dev environment root |
| `infrastructure/environments/stage` | Deployable stage environment root |
| `infrastructure/environments/prod` | Deployable prod environment root |
| `infrastructure/modules/ecs-fargate-platform/01-identity-access.tf` | KMS and ECS task IAM |
| `infrastructure/modules/ecs-fargate-platform/02-network-foundation.tf` | VPC, subnets, security groups, and VPC endpoints |
| `infrastructure/modules/ecs-fargate-platform/03-container-platform.tf` | ECR, ALB, ECS cluster, task definition, and service |
| `infrastructure/modules/ecs-fargate-platform/04-observability-operations.tf` | CloudWatch application logs |

## Deployment Notes

<!--
==============================================================================
DEPLOYMENT NOTES
==============================================================================
-->

The workload uses private subnets.

Private ECS tasks need access to ECR image APIs, ECR image layers in S3, and CloudWatch Logs.

The default path uses VPC endpoints:

```hcl
enable_vpc_endpoints = true
enable_nat_gateway   = false
```

Set `enable_nat_gateway = true` only when the workload needs broader outbound internet access.

NAT Gateway has hourly and data processing costs.

## Manual Flow

<!--
==============================================================================
MANUAL DEPLOYMENT FLOW
==============================================================================
-->

1. Run `terraform init` and `terraform apply` in `infrastructure/00-identity-bootstrap`.
2. Add the output role ARN as the GitHub repository variable `AWS_ROLE_TO_ASSUME`.
3. Attach account-specific permissions to the OIDC role through `managed_policy_arns` or your own IAM process.
4. Run the validation workflow.
5. Run the deploy workflow with the required confirmation phrase.
