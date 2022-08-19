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



