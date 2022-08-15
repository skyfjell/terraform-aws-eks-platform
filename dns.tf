/*
In order to get DNS working on the cluster, we need to setup 
email associated with module and route53.
*/


// Email

locals {
  // The ses module automatically add a 'Name' tag so we need to ignore 
  //   ours for the time to avoid the conflict
  tags_prepared         = { for k, v in local.labels.tags : k => v if lower(k) != "name" }
  domain_zones          = local.config_dns.domain_zones
  service_account       = "system:serviceaccount:${local.config_dns.irsa.namespace}:${local.config_dns.irsa.service_account}"
  configure_externaldns = length(local.domain_zones) > 0
  configure_extra_dns   = length(local.domain_zones) > 1 ? slice(local.domain_zones, 1, length(local.domain_zones)) : []

}

module "ses" {
  count   = local.configure_externaldns ? 1 : 0
  source  = "cloudposse/ses/aws"
  version = "0.22.3"

  enabled       = true
  name          = "ses-${local.labels.id}-${local.domain_zones[0].domain}"
  domain        = local.domain_zones[0].domain
  zone_id       = local.domain_zones[0].zone_id
  verify_dkim   = true
  verify_domain = true


  tags = local.tags_prepared
}

// Additional Domains

resource "aws_ses_domain_identity" "ses_domain" {
  for_each = { for x in local.configure_extra_dns : x.domain => x }

  domain = each.value.domain
}

resource "aws_route53_record" "amazonses_verification_record" {
  for_each = { for x in local.configure_extra_dns : x.domain => x }

  zone_id = each.value.zone_id
  name    = "_amazonses.${each.value.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.ses_domain[each.value.name].verification_token]
}

// Policy Docs

data "aws_iam_policy_document" "external_dns_policy_doc" {
  count = local.configure_externaldns ? 1 : 0

  statement {
    sid    = "ChangeRoute53ExternalDNS"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [for x in local.domain_zones : "arn:aws:route53:::hostedzone/${x.zone_id}"]
  }

  statement {
    sid    = "ReadRoute53ExternalDNS"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:GetChange",
      "route53:ListResourceRecordSets"
    ]
    # TODO: Do we need to limit resources or conditions here?
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_policy_doc" {
  statement {
    sid     = "AssumeRoleWithWebIdentity"
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
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_id}:sub"
      values   = [local.service_account]
    }
  }
  statement {
    sid     = "AssumeRolePolicyStatement"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/eks:cluster-name"
      values   = [local.labels.id]
    }
  }

}

// ## Policies

resource "aws_iam_policy" "externaldns_service_role" {
  count = local.configure_externaldns ? 1 : 0

  name        = "${local.labels.id}-external-dns-role"
  path        = "/"
  description = "EKS role for External-DNS"
  policy      = data.aws_iam_policy_document.external_dns_policy_doc[0].json
}

// ## Roles

resource "aws_iam_role" "externaldns_service_role" {
  name               = "${local.labels.id}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.assume_policy_doc.json
}

// ## Attachments

resource "aws_iam_role_policy_attachment" "externaldns_service_role" {
  count      = local.configure_externaldns ? 1 : 0
  role       = aws_iam_role.externaldns_service_role.name
  policy_arn = aws_iam_policy.externaldns_service_role[0].arn
}

resource "aws_iam_role_policy_attachment" "externaldns_service_list" {
  count      = local.configure_externaldns && local.cluster.install ? 1 : 0
  role       = module.cluster.cluster_iam_role_name
  policy_arn = aws_iam_policy.externaldns_service_role[0].arn
}

