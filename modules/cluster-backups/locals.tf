locals {
  oidc_id        = var.oidc_id
  cluster_id     = var.oidc_id
  velero_version = var.velero_version
  labels         = var.labels
  bucket_id      = var.bucket_id
  create_bucket  = var.bucket_id == null
}
