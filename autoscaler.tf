resource "aws_iam_role" "autoscaler" {
  count = local.autoscaler.enable_service_account ? 1 : 0

  name_prefix        = join("-", ["${local.labels.id}", "eks_autoscaler"])
  assume_role_policy = data.aws_iam_policy_document.autoscaler_assume.json

  tags = local.labels.tags
}

data "aws_iam_policy_document" "autoscaler_assume" {
  statement {
    sid     = "ClusterOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_id}:sub"
      values = [
        "sts.amazonaws.com",
        "system:serviceaccount:kube-system:aws-node",
        "system:serviceaccount:kube-system:cluster-autoscaler"
      ]
    }
  }
}

data "aws_iam_policy_document" "autoscaler" {
  // checkov:skip=CKV_AWS_111: Conditions on managed tags constrain
  statement {
    sid    = "ClusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    # TODO: Do we need to limit resources or conditions here?
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.labels.id}"
      values   = ["owned"]
    }
  }

  statement {
    sid    = "ClusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeInstanceTypes",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${local.labels.id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "autoscaler" {
  count = local.autoscaler.enable_service_account ? 1 : 0

  name_prefix = join("-", ["${local.labels.id}", "eks_autoscaler"])
  path        = "/"
  description = "EKS role for AWS Autoscaler"
  policy      = data.aws_iam_policy_document.autoscaler.json

  tags = local.labels.tags
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  count = local.autoscaler.enable_service_account ? 1 : 0

  role       = aws_iam_role.autoscaler[0].name
  policy_arn = aws_iam_policy.autoscaler[0].arn
}

resource "kubernetes_namespace" "autoscaler" {
  count = local.autoscaler.enable_service_account ? 1 : 0
  metadata {
    name = local.autoscaler.namespace
    labels = {
      "app.kubernetes.io/managed-by"          = "Terraform"
      "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform/autoscaler.tf"
      "app.kubernetes.io/created-by-instance" = local.labels.id
      "app.kubernetes.io/part-of"             = "autoscaler"
      "app.kubernetes.io/component"           = "aws-access"
    }
  }
}

resource "kubernetes_service_account" "autoscaler" {
  count = local.autoscaler.enable_service_account ? 1 : 0
  metadata {
    name      = "autoscaler"
    namespace = local.autoscaler.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.autoscaler[0].arn
    }
    labels = {
      "app.kubernetes.io/managed-by"          = "Terraform"
      "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform/autoscaler.tf"
      "app.kubernetes.io/created-by-instance" = local.labels.id
      "app.kubernetes.io/part-of"             = "autoscaler"
      "app.kubernetes.io/component"           = "aws-access"
    }
  }

  depends_on = [kubernetes_namespace.autoscaler[0]]
}
