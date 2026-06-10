<!--
==============================================================================
DEVOPS PLATFORM BLUEPRINTS README
==============================================================================
-->

# DevOps Platform Blueprints

Public, forkable DevOps platform blueprints built to show production-style infrastructure, delivery, security, and operations patterns.

This repo is the implementation layer above reusable modules. It consumes modules from:

```text
https://github.com/bharathadigopula/terraform-aws-modules
```

The first blueprint pins that module repo to release tag:

```text
v0.1.0
```

## Module Reference Policy

<!--
==============================================================================
MODULE REFERENCE POLICY
==============================================================================
-->

Blueprints should consume `terraform-aws-modules` using stable release tags.

Current module release:

```text
v0.1.0
```

Blueprint module sources use:

```hcl
ref=v0.1.0
```

## Blueprints

<!--
==============================================================================
BLUEPRINT CATALOG
==============================================================================
-->

| Blueprint | Status | Purpose |
| --- | --- | --- |
| `aws-ecs-fargate-github-oidc` | MVP | Deploy a private ECS Fargate workload behind a public ALB using GitHub Actions OIDC |

## Infrastructure Layers

<!--
==============================================================================
INFRASTRUCTURE LAYER MODEL
==============================================================================
-->

The ECS blueprint keeps the reusable platform implementation in a local Terraform module.

Each environment root calls that module with environment-specific network ranges, scaling defaults, and operational settings.

| Layer | Purpose |
| --- | --- |
| `00-identity-bootstrap` | One-time GitHub OIDC role setup |
| `modules/ecs-fargate-platform/00-context.tf` | Shared AWS data and naming locals |
| `modules/ecs-fargate-platform/01-identity-access.tf` | KMS and ECS task IAM |
| `modules/ecs-fargate-platform/02-network-foundation.tf` | VPC, subnets, security groups, and private service endpoints |
| `modules/ecs-fargate-platform/03-container-platform.tf` | ECR, ALB, ECS cluster, task definition, and service |
| `modules/ecs-fargate-platform/04-observability-operations.tf` | CloudWatch application logs |

Environment roots:

```text
blueprints/aws-ecs-fargate-github-oidc/infrastructure/environments/dev
blueprints/aws-ecs-fargate-github-oidc/infrastructure/environments/stage
blueprints/aws-ecs-fargate-github-oidc/infrastructure/environments/prod
```

## Portfolio Story

<!--
==============================================================================
PORTFOLIO POSITIONING
==============================================================================
-->

| Repo | Role |
| --- | --- |
| `terraform-aws-modules` | Reusable AWS building blocks |
| `devops-platform-blueprints` | Real platform implementations using those blocks |
| `devops-content-engine` | Content and publishing automation around the portfolio |

## Safety Model

<!--
==============================================================================
PUBLIC REPO SAFETY MODEL
==============================================================================
-->

The blueprints are public and designed for learning, forking, and adaptation.

Deploy workflows are manual.

Apply workflows require an explicit confirmation phrase.

AWS credentials are expected through OIDC, not long-lived access keys.

Cost-bearing options are visible in Terraform variables.
