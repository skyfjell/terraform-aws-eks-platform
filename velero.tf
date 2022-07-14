locals {
  velero_tf = {
    install = local.cluster.install && local.config_velero.install
  }
}

module "velero" {
  count  = local.velero_tf.install ? 1 : 0
  source = "./modules/cluster-backups"

  oidc_id        = local.oidc_id
  cluster_id     = local.labels.id
  velero_version = local.config_velero.version
  labels         = local.labels
  bucket_id      = local.config_velero.bucket
}
