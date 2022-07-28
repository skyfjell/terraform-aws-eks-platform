
module "velero" {
  source = "./modules/cluster-backups"

  install        = local.config_velero.install && local.cluster.install
  oidc_id        = local.oidc_id
  cluster_id     = local.labels.id
  velero_version = local.config_velero.version
  labels         = local.labels
  config_bucket  = local.config_velero.config_bucket
}
