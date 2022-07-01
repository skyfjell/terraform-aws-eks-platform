// locals

locals {
  oidc_id = trimprefix(module.cluster.cluster_oidc_issuer_url, "https://")
}


// Policy Docs

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_id}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

// Policies


// Roles

resource "aws_iam_role" "eks_oidc_role" {
  name_prefix        = "eks_oidc_role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

// Attachments
