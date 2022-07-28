output "s3" {
  value = {
    id  = local.install ? data.aws_s3_bucket.this.0.id : null
    arn = local.install ? data.aws_s3_bucket.this.0.arn : null
  }
  description = "S3 bucket object where velero stores its backups."
}

output "role" {
  value = local.install ? {
    arn = aws_iam_role.velero.0.arn
  } : null
  description = "Object with arn of the role that the velero service account assumes."
}

