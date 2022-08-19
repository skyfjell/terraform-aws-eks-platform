/*
In order to get DNS working on the cluster, we need to setup 
email associated with module and route53.
*/


// Email

locals {
  // The ses module automatically add a 'Name' tag so we need to ignore 
  //   ours for the time to avoid the conflict
  tags_prepared         = { for k, v in local.labels.tags : k => v if lower(k) != "name" }
  configure_externaldns = length(local.config_dns.domain_zone_ids) > 0
  configure_extra_dns   = length(local.config_dns.domain_zone_ids) > 1 ? slice(local.config_dns.domain_zone_ids, 1, length(local.config_dns.domain_zone_ids)) : []
  hosted_zone_arns      = [for x in local.config_dns.domain_zone_ids : "arn:aws:route53:::hostedzone/${x}"]
}

data "aws_route53_zone" "domains" {
  for_each = { for x in local.config_dns.domain_zone_ids : x => x }
  zone_id  = each.value
}

module "ses" {
  count   = local.configure_externaldns ? 1 : 0
  source  = "cloudposse/ses/aws"
  version = "0.22.3"

  enabled       = true
  name          = "ses-${local.labels.id}-${data.aws_route53_zone.domains[local.config_dns.domain_zone_ids[0]].name}"
  domain        = data.aws_route53_zone.domains[local.config_dns.domain_zone_ids[0]].name
  zone_id       = local.config_dns.domain_zone_ids[0]
  verify_dkim   = true
  verify_domain = true


  tags = local.tags_prepared
}

// Additional Domains

resource "aws_ses_domain_identity" "ses_domain" {
  for_each = { for x in local.configure_extra_dns : x => x }

  domain = data.aws_route53_zone.domains[each.value].name
}

resource "aws_route53_record" "amazonses_verification_record" {
  for_each = { for x in local.configure_extra_dns : x => x }

  zone_id = each.value
  name    = "_amazonses.${each.value}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.ses_domain[each.value].verification_token]
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

    resources = local.hosted_zone_arns
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



