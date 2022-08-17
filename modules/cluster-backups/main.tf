locals {
  server_side_encryption_configuration = local.config_bucket.server_side_encryption_configuration == null ? {
    type = "aws:kms"
  } : local.config_bucket.server_side_encryption_configuration

}


module "backups_bucket" {
  count = local.config_bucket.enable && local.config_bucket.existing_id == null ? 1 : 0

  source  = "skyfjell/s3/aws"
  version = "1.0.5"

  use_prefix                           = false
  name                                 = "velero-backup"
  logging                              = null
  server_side_encryption_configuration = local.server_side_encryption_configuration

  labels = local.labels

  roles = local.install ? [{
    name = aws_iam_role.velero.0.name
    mode = "RW"
  }] : []

  policy_conditions = local.install ? {
    RW = {
      "velero" = {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          aws_iam_role.velero.0.arn
        ]
      }
    }
  } : {}
}

data "aws_s3_bucket" "this" {
  count  = var.config_bucket.enable ? 1 : 0
  bucket = local.config_bucket.existing_id != null ? local.config_bucket.existing_id : one(module.backups_bucket.*.s3.id)
}

resource "helm_release" "velero" {
  count = local.install ? 1 : 0

  name             = "velero"
  namespace        = "velero" # we should hard code this here
  version          = local.velero_version
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  create_namespace = true


  values = [yamlencode({
    labels = {
      "app.kubernetes.io/managed-by"          = "Terraform"
      "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform"
      "app.kubernetes.io/created-by-instance" = local.labels.id
      "app.kubernetes.io/part-of"             = "velero"
    }
    configuration = {
      provider = "aws"
      backupStorageLocation = {
        bucket = one(data.aws_s3_bucket.this.*.id)
        config = merge({
          region = data.aws_region.current.name
          s3Url  = "https://s3.us-east-2.amazonaws.com"
        }, local.use_kms ? { kmsKeyId = one(data.aws_kms_key.kms.*.arn) } : {})
      }
      volumeSnapshotLocation = {
        name = "default"
        config = {
          region = data.aws_region.current.name
        }
      }
    }
    initContainers = [{
      name  = "velero-plugin-for-aws"
      image = "velero/velero-plugin-for-aws:v1.4.1"
      volumeMounts = [{
        mountPath = "/target"
        name      = "plugins"
      }]
    }]
    nodeSelector = { "skyfjell.io/node-selector" : "platform-system" }
    serviceAccount = {
      server = {
        annotations = {
          "eks.amazonaws.com/role-arn" = one(aws_iam_role.velero.*.arn)
        }
      }
    }
    credentials = {
      useSecret = false
    }
  })]
}
