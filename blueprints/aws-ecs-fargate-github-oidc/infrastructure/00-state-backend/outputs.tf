#==============================================================================
# STATE BACKEND OUTPUTS
#==============================================================================

output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN for Terraform state"
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.locks.name
}

output "lock_table_arn" {
  description = "DynamoDB table ARN for Terraform state locking"
  value       = aws_dynamodb_table.locks.arn
}

output "state_kms_key_arn" {
  description = "KMS key ARN for Terraform state encryption"
  value       = aws_kms_key.state.arn
}

output "state_kms_alias_name" {
  description = "KMS alias name for Terraform state encryption"
  value       = aws_kms_alias.state.name
}
