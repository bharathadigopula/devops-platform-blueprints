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

The ECS blueprint keeps the deployable environment in one Terraform root for now, with layer files inside that root.

This avoids early cross-state complexity while still keeping the platform design easy to read.

| Layer | Purpose |
| --- | --- |
| `00-identity-bootstrap` | One-time GitHub OIDC role setup |
| `00-context.tf` | Shared AWS data and naming locals |
| `01-identity-access.tf` | KMS and ECS task IAM |
| `02-network-foundation.tf` | VPC, subnets, security groups, and private service endpoints |
| `03-container-platform.tf` | ECR, ALB, ECS cluster, task definition, and service |
| `04-observability-operations.tf` | CloudWatch application logs |

Environment roots live under:

```text
blueprints/aws-ecs-fargate-github-oidc/infrastructure/environments/dev
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
