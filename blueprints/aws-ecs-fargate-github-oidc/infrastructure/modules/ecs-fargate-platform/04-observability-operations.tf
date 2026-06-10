#==============================================================================
# CLOUDWATCH LOGS
#==============================================================================

module "logs" {
  source = "git::https://github.com/bharathadigopula/terraform-aws-modules.git//modules/management/cloudwatch-logs?ref=v0.1.0"

  log_groups = [
    {
      name              = local.log_group_name
      retention_in_days = var.log_retention_days
      log_group_class   = "STANDARD"
      tags              = local.tags
    }
  ]

  tags = local.tags
}
