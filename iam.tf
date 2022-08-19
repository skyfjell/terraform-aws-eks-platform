locals {
  hosted_zone_arns = [for x in local.config_dns.domain_zones : "arn:aws:route53:::hostedzone/${x.zone_id}"]
}

module "platform_view_iam" {
  count = length(local.users.view) > 0 ? 1 : 0

  source = "./modules/cluster-iam"

  labels      = local.labels
  name        = "platform-view"
  user_arns   = local.users.view
  actions     = ["eks:DescribeCluster"]
  cluster_arn = module.cluster.cluster_arn
  attach      = local.cluster.install
}

module "platform_edit_iam" {
  count = length(local.users.edit) > 0 ? 1 : 0

  source = "./modules/cluster-iam"

  labels      = local.labels
  name        = "platform-edit"
  user_arns   = local.users.edit
  actions     = ["eks:*"]
  cluster_arn = module.cluster.cluster_arn
  attach      = local.cluster.install
}


module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name = "ebs-csi-${local.labels.id}"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-node-sa", "kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name                     = "cert-manager-${local.labels.id}"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = local.hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_dns.irsa.cert_manager
    }
  }
}

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name                     = "external-dns-${local.labels.id}"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = local.hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_dns.irsa.external_dns
    }
  }
}
