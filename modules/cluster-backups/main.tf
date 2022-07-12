
module "backups_bucket" {
  count = local.create_bucket ? 1 : 0

  source  = "skyfjell/s3/aws"
  version = "1.0.1"

  use_prefix    = false
  name          = "velero-backup"
  logging       = null
  sse_algorithm = "AES256"

  labels = local.labels

  roles = [{
    name = aws_iam_role.velero.name
    mode = "RW"
  }]

  policy_conditions = {
    RW = {
      "velero" = {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          aws_iam_role.velero.arn
        ]
      }
    }
  }
}

data "aws_s3_bucket" "this" {
  bucket = local.create_bucket ? module.backups_bucket[0].s3_id : local.bucket_id
}

resource "helm_release" "velero" {
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
        bucket = data.aws_s3_bucket.this.id
        config = {
          region = data.aws_region.current.name
          s3Url  = "https://s3.us-east-2.amazonaws.com"
        }
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
    nodeSelector = {
      spec = "platform-system"
    }
    serviceAccount = {
      server = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
        }
      }
    }
    credentials = {
      useSecret = false
    }
  })]
}
