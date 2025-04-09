# Version générique du fichier terraform_locals.tf
# Ce fichier remplace terraform_locals.tf

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.name

  app_name = "refresh-env-efs-${var.app_name}-${var.env_name}"

  name    = local.app_name
  name_cc = replace(title(local.name), "-", "")

  # ARNs génériques pour les ressources
  generic_efs_arn            = "arn:aws:elasticfilesystem:${local.current_region}:${local.current_account_id}:file-system/*"
  generic_security_group_arn = "arn:aws:ec2:${local.current_region}:${local.current_account_id}:security-group/*"

  # Bucket S3
  refresh_bucket_id = var.s3_bucket_name == null ? (
    var.create_s3_bucket ? aws_s3_bucket.refresh_bucket[0].id : null
  ) : var.s3_bucket_name
}
