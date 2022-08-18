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
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "ebs-csi-${local.labels.id}"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-node-sa", "kube-system:ebs-csi-controller-sa"]
    }
  }
}
