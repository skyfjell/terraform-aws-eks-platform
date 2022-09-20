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
  count = local.cluster.install ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.4.0"

  role_name = "${local.labels.id}-ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-node-sa", "kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "cert_manager_irsa" {
  count   = length(local.hosted_zone_arns) > 0 && length(local.config_dns.service_accounts.cert_manager) > 0 ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.4.0"

  role_name                     = "${local.labels.id}-cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = local.hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_dns.service_accounts.cert_manager
    }
  }
}

module "external_dns_irsa" {
  count = length(local.hosted_zone_arns) > 0 && length(local.config_dns.service_accounts.external_dns) > 0 ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.4.0"

  role_name                     = "${local.labels.id}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = local.hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_dns.service_accounts.external_dns
    }
  }
}

module "velero_irsa" {
  count   = local.config_velero.enable && length(local.config_velero.service_accounts.velero) > 0 ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.4.0"

  role_name             = "${local.labels.id}-velero"
  attach_velero_policy  = true
  velero_s3_bucket_arns = data.aws_s3_bucket.velero.*.arn

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = local.config_velero.service_accounts.velero
    }
  }
}

data "aws_iam_policy_document" "velero_kms" {
  count = length(module.velero_irsa) > 0 && local.use_kms ? 1 : 0

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      one(data.aws_kms_key.velero_kms.*.arn)
    ]
  }

  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = [
      one(data.aws_kms_key.velero_kms.*.arn)
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
}

resource "aws_iam_policy" "velero_irsa_kms" {
  count = length(module.velero_irsa) > 0 && local.use_kms ? 1 : 0

  name   = "${local.labels.id}-velero-irsa-kms"
  policy = one(data.aws_iam_policy_document.velero_kms.*.json)
}

resource "aws_iam_role_policy_attachment" "velero_irsa_kms" {
  count = length(module.velero_irsa) > 0 && local.use_kms ? 1 : 0

  role       = one(module.velero_irsa.*.iam_role_name)
  policy_arn = one(aws_iam_policy.velero_irsa_kms.*.arn)
}
