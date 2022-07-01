
data "aws_iam_policy_document" "velero" {
  // checkov:skip=CKV_AWS_111: Conditions on managed tags constrain
  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "${data.aws_s3_bucket.this.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [data.aws_s3_bucket.this.arn]
  }

  statement {
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
  name_prefix = "velero_backups_policy"
  policy      = data.aws_iam_policy_document.velero.json
  description = "Velero s3 IAM access"
  tags        = local.labels.tags
}

// Roles 

resource "aws_iam_role" "velero" {
  name_prefix        = "velero_backups"
  assume_role_policy = data.aws_iam_policy_document.velero_assume.json
  tags               = local.labels.tags
}

// Attachments

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.velero.name
  policy_arn = aws_iam_policy.velero.arn
}

