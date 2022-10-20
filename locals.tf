locals {
  labels = {
    id = var.labels.id
    tags = merge(var.labels.tags, {
      "app.kubernetes.io/managed-by"          = "Terraform"
      "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform"
      "app.kubernetes.io/created-by-instance" = var.labels.id
    })
  }

  # Cluster Config
  cluster = var.cluster

  managed_node_groups = var.managed_node_groups
  cluster_id          = module.cluster.cluster_id

  users = {
    edit = var.users.edit == null ? [] : var.users.edit,
    view = var.users.view == null ? [] : var.users.view,
  }

  config_dns = merge(var.config_dns, {
    service_accounts = {
      external_dns = try(var.config_dns.service_accounts.external-dns, ["external-dns:external-dns"])
      cert_manager = try(var.config_dns.service_accounts.cert_manager, ["cert-manager:cert-manager"])
  } })

  # Services and Applications
  config_autoscaler = var.config_autoscaler

  config_flux = var.config_flux

  hosted_zone_arns = [for x in local.config_dns.hosted_zone_ids : "arn:aws:route53:::hostedzone/${x}"]


  config_velero = merge(var.config_velero, {
    server_side_encryption_configuration = merge(
      var.config_velero.server_side_encryption_configuration,
      {
        alias = var.config_velero.server_side_encryption_configuration.alias != null ? var.config_velero.server_side_encryption_configuration.alias : "alias/${local.labels.id}-velero"
      }
    )
  })

  config_karpenter = var.config_karpenter

  partition = data.aws_partition.current.partition
}
