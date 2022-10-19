resource "aws_iam_instance_profile" "karpenter" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  name = "KarpenterNodeInstanceProfile-${local.labels.id}"
  role = module.cluster.eks_managed_node_groups["default"].iam_role_name
}

module "karpenter_irsa" {
  # count = local.cluster.install && local.config_karpenter.install ? 1 : 0
  count = 1

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.5.2"

  role_name                          = "karpenter-controller-${local.labels.id}"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_id = module.cluster.cluster_id
  karpenter_controller_node_iam_role_arns = [
    module.cluster.eks_managed_node_groups["default"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

resource "helm_release" "karpenter" {
  # count = local.cluster.install && local.config_karpenter.install ? 1 : 0
  count = 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.16.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = one(module.karpenter_irsa.*.iam_role_arn)
  }

  set {
    name  = "clusterName"
    value = module.cluster.cluster_id
  }

  set {
    name  = "clusterEndpoint"
    value = module.cluster.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = one(aws_iam_instance_profile.karpenter.*.name)
  }

  values = [yamlencode({
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    }]
  })]

  depends_on = [
    aws_iam_instance_profile.karpenter,
    module.karpenter_irsa
  ]
}
