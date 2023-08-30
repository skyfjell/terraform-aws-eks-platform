resource "aws_iam_instance_profile" "karpenter" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  name = "KarpenterNodeInstanceProfile-${local.labels.id}"
  role = module.cluster.eks_managed_node_groups["default"].iam_role_name
}

module "karpenter_irsa" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5.5.2, < 6.0.0"

  role_name                          = "karpenter-controller-${local.labels.id}"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = module.cluster.cluster_name
  karpenter_controller_node_iam_role_arns = [
    module.cluster.eks_managed_node_groups["default"].iam_role_arn
  ]

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  depends_on = [
    aws_iam_instance_profile.karpenter
  ]
}

resource "helm_release" "karpenter" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.29.2"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa[0].iam_role_arn
  }
  set {
    name  = "settings.aws.clusterName"
    value = module.cluster.cluster_name
  }
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter[0].name
  }
  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.cluster.cluster_name
  }
  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.cluster.cluster_endpoint
  }
  set {
    name  = "replicas"
    value = local.config_karpenter.replicas
  }

  dynamic "set" {
    for_each = local.config_karpenter.additionalValues
    content {
      name  = set.key
      value = set.value
    }
  }

  values = [yamlencode({
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    }]
  })]

  depends_on = [
    module.karpenter_irsa
  ]
}
