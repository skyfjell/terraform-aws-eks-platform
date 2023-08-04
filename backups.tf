locals {
  server_side_encryption_configuration = local.config_velero.server_side_encryption_configuration == null ? {
    type = "aws:kms"
  } : local.config_velero.server_side_encryption_configuration
  create_bucket = local.config_velero.enable && local.config_velero.existing_id == null
  use_kms       = local.config_velero.enable && try(coalesce(local.config_velero.server_side_encryption_configuration.type), "aws:kms") == "aws:kms"
  kms_alias     = try(local.config_velero.server_side_encryption_configuration.alias, null)
  kms_id        = try(local.config_velero.server_side_encryption_configuration.kms_master_key_id, null)
  kms_key_id    = local.config_velero.enable && local.config_velero.existing_id == null ? one(module.velero_bucket.*.kms_arn) : try(coalesce(local.kms_alias), coalesce(local.kms_id), "")
}


module "velero_bucket" {
  count = local.create_bucket ? 1 : 0

  source  = "skyfjell/s3/aws"
  version = ">= 1.0.8"

  use_prefix = false
  name       = "${local.labels.id}-velero"
  config_logging = {
    enable = false
  }
  server_side_encryption_configuration = local.server_side_encryption_configuration
  labels                               = local.labels
}


data "aws_s3_bucket" "velero" {
  count  = local.config_velero.enable ? 1 : 0
  bucket = local.config_velero.existing_id == null ? one(module.velero_bucket.*.bucket.id) : local.config_velero.existing_id
}

data "aws_kms_key" "velero_kms" {
  count  = local.use_kms ? 1 : 0
  key_id = local.config_velero.enable && local.config_velero.existing_id == null ? one(module.velero_bucket.*.kms_arn) : try(coalesce(local.kms_alias), coalesce(local.kms_id), "")
}

