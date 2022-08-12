locals {
  sse_type  = try(local.config_bucket.server_side_encryption_configuration.type, null)
  kms_alias = try(local.config_bucket.server_side_encryption_configuration.alias, null)
  kms_id    = try(local.config_bucket.server_side_encryption_configuration.kms_master_key_id, null)
  use_kms   = local.config_bucket.enable && local.sse_type == "aws:kms"
}


data "aws_kms_key" "kms" {
  count  = local.use_kms ? 1 : 0
  key_id = local.config_bucket.enable ? one(module.backups_bucket.*.kms_arn) : try(coalesce(local.kms_alias), coalesce(local.kms_id), "")
}

data "aws_iam_policy_document" "kms" {
  count = local.use_kms ? 1 : 0
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:*"
    ]
    resources = [one(data.aws_kms_key.kms.*.arn)]
  }
}

data "aws_iam_policy_document" "backups" {
  count = local.install ? 1 : 0
  // checkov:skip=CKV_AWS_111: Conditions on managed tags constrain
  statement {
    sid = "S3Bucket"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = try(["${coalesce(one(data.aws_s3_bucket.this.*.arn))}"], [])
  }

  statement {
    sid = "S3List"
    actions = [
      "s3:ListBucket"
    ]
    resources = try([coalesce(one(data.aws_s3_bucket.this.*.arn))], [])
  }

  statement {
    sid = "EC2List"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.labels.id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/created-by-instance"
      values   = [local.labels.id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/created-by"
      values   = ["terraform-aws-eks-platform"]
    }
  }
}



data "aws_iam_policy_document" "velero" {
  source_policy_documents = concat([
    data.aws_iam_policy_document.backup.json],
  local.use_kms ? [one(data.aws_iam_policy_document.kms.*.json)] : [])

}

data "aws_iam_policy_document" "velero_assume" {
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
        "system:serviceaccount:velero:velero-server"
      ]
    }
  }
}

// Policies 

resource "aws_iam_policy" "velero" {
  count = local.install ? 1 : 0

  name_prefix = "velero_backups_policy"
  policy      = one(data.aws_iam_policy_document.velero.*.json)
  description = "Velero s3 IAM access"
  tags        = local.labels.tags
}

// Roles 

resource "aws_iam_role" "velero" {
  count = local.install ? 1 : 0

  name_prefix        = "velero_backups"
  assume_role_policy = data.aws_iam_policy_document.velero_assume.json
  tags               = local.labels.tags
}

// Attachments

resource "aws_iam_role_policy_attachment" "this" {
  count = local.install ? 1 : 0

  role       = aws_iam_role.velero.0.name
  policy_arn = aws_iam_policy.velero.0.arn
}

