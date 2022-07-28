output "s3" {
  value = {
    id  = local.bucket_exists ? one(data.aws_s3_bucket.this.*.id) : null
    arn = local.bucket_exists ? one(data.aws_s3_bucket.this.*.arn) : null
  }
  description = "S3 bucket object where velero stores its backups."
}

output "role" {
  value = local.install ? {
    arn = aws_iam_role.velero.0.arn
  } : null
  description = "Object with arn of the role that the velero service account assumes."
}

