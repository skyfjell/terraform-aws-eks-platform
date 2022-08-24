locals {
  install        = var.install
  oidc_id        = var.oidc_id
  cluster_id     = var.oidc_id
  velero_version = var.velero_version
  labels         = var.labels
  config_bucket = defaults(var.config_bucket, {
    enable = true
    # existing_id = []
    server_side_encryption_configuration = {
      type = "aws:kms"
    }
  })

}

