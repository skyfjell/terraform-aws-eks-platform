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

  cluster_name = module.cluster.cluster_name

  users = {
    edit = var.users.edit == null ? [] : var.users.edit,
    view = var.users.view == null ? [] : var.users.view,
  }

  config_dns = var.config_dns

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

  config_karpenter = merge(var.config_karpenter, {
    additionalValues = {
      "controller.resources.limits.memory"   = try(var.config_karpenter.additionalValues["controller.resources.limits.memory"], "1Gi")
      "controller.resources.requests.memory" = try(var.config_karpenter.additionalValues["controller.resources.requests.memory"], "1Gi")
      "controller.resources.limits.cpu"      = try(var.config_karpenter.additionalValues["controller.resources.limits.cpu"], "1000m")
      "controller.resources.requests.cpu"    = try(var.config_karpenter.additionalValues["controller.resources.requests.cpu"], "1000m")
    }
  })

  partition = data.aws_partition.current.partition
}
