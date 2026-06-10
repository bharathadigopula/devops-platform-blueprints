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

The first blueprint pins that module repo to commit:

```text
62c1cedd48e63734528c67720bb157df22f6c738
```

After the first module release tag is published, update module sources to:

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

Current bootstrap state:

```text
Pinned commit: 62c1cedd48e63734528c67720bb157df22f6c738
Planned release tag: v0.1.0
```

After `v0.1.0` is created in `terraform-aws-modules`, replace commit refs with:

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
