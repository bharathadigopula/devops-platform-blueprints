#==============================================================================
# ACCOUNT DATA
#==============================================================================

data "aws_caller_identity" "current" {}

#==============================================================================
# LOCAL VALUES
#==============================================================================

locals {
  bucket_name     = coalesce(var.state_bucket_name, lower("${var.project_name}-${var.state_name}-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"))
  lock_table_name = coalesce(var.lock_table_name, "${var.project_name}-${var.state_name}-terraform-locks")
  kms_alias_name  = "alias/${var.project_name}-${var.state_name}-tfstate"

  tags = merge(
    var.tags,
    {
      Blueprint   = "aws-ecs-fargate-github-oidc"
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
      Purpose     = "terraform-state"
    }
  )
}

#==============================================================================
# STATE KMS KEY
#==============================================================================

resource "aws_kms_key" "state" {
  description             = "Terraform state encryption key for ${var.project_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.tags
}

resource "aws_kms_alias" "state" {
  name          = local.kms_alias_name
  target_key_id = aws_kms_key.state.key_id
}

#==============================================================================
# STATE S3 BUCKET
#==============================================================================

resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy_state_bucket
  tags          = merge(local.tags, { Name = local.bucket_name })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

#==============================================================================
# STATE S3 BUCKET POLICY
#==============================================================================

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json
}

#==============================================================================
# STATE LOCK TABLE
#==============================================================================

resource "aws_dynamodb_table" "locks" {
  name                        = local.lock_table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "LockID"
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  tags = merge(local.tags, { Name = local.lock_table_name })
}
