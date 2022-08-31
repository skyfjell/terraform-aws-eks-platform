locals {
  server_side_encryption_configuration = local.config_velero.server_side_encryption_configuration == null ? {
    type = "aws:kms"
  } : local.config_velero.server_side_encryption_configuration
  create_bucket = local.config_velero.enable && local.config_velero.existing_id == null
  sse_type      = try(local.config_velero.server_side_encryption_configuration.type, "aws:kms")
  use_kms       = local.config_velero.enable && local.sse_type == "aws:kms"
  kms_alias     = try(local.config_velero.server_side_encryption_configuration.alias, null)
  kms_id        = try(local.config_velero.server_side_encryption_configuration.kms_master_key_id, null)
}


module "velero_bucket" {
  count = local.create_bucket ? 1 : 0

  source  = "skyfjell/s3/aws"
  version = "1.0.5"

  use_prefix                           = false
  name                                 = "${local.labels.id}-velero"
  logging                              = null
  server_side_encryption_configuration = local.server_side_encryption_configuration
  labels                               = local.labels
}


data "aws_s3_bucket" "velero" {
  count  = local.config_velero.enable ? 1 : 0
  bucket = local.config_velero.existing_id == null ? one(module.velero_bucket.*.s3.id) : local.config_velero.existing_id
}

data "aws_kms_key" "kms" {
  count  = local.use_kms ? 1 : 0
  key_id = local.config_velero.enable && local.config_velero.existing_id == null ? one(module.velero_bucket.*.kms_arn) : try(coalesce(local.kms_alias), coalesce(local.kms_id), "")
}

module "velero_iam" {
  count   = local.config_velero.enable && length(local.config_velero.service_accounts.velero) > 0 ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name             = "${local.labels.id}-velero"
  attach_velero_policy  = true
  velero_s3_bucket_arns = data.aws_s3_bucket.velero.*.arn

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_velero.service_accounts.velero
    }
  }
}