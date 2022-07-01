output "s3" {
  value = {
    id  = data.aws_s3_bucket.this.id
    arn = data.aws_s3_bucket.this.arn
  }
  description = "S3 bucket object where velero stores its backups."
}

output "role" {
  value = {
    arn = aws_iam_role.velero.arn
  }
  description = "Object with arn of the role that the velero service account assumes."
}
