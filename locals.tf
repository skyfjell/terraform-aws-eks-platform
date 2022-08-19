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
  cluster = defaults(var.cluster, {
    install = true,
    destroy = false
  })

  managed_node_groups = var.managed_node_groups
  cluster_id          = module.cluster.cluster_id

  users = {
    edit = var.users.edit == null ? [] : var.users.edit,
    view = var.users.view == null ? [] : var.users.view,
  }

  config_dns = merge(var.config_dns, { irsa = {
    external_dns = [for sa in try(var.config_dns.irsa.external-dns, []) : sa]
    cert_manager = [for sa in try(var.config_dns.irsa.external-dns, []) : sa]
  } })

  # Services and Applications
  config_autoscaler = var.config_autoscaler

  config_flux = defaults(var.config_flux, {
    install = local.cluster.install,
    git = {
      create_ssh_key = true,
    }
  })


  config_velero = defaults(var.config_velero, {
    install = true
    version = "2.30.1"
    config_bucket = {
      enable = true
      server_side_encryption_configuration = {
        type = "aws:kms"
      }
    }
    }
  )

  config_karpenter = defaults(var.config_karpenter, {
    install = local.cluster.install,
  })

  partition = data.aws_partition.current.partition
}
