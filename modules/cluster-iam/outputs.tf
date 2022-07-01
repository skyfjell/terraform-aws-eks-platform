output "role" {
  description = "Role object created"
  value       = aws_iam_role.this
}

output "aws_auth_role" {
  description = "aws_auth_roles formatted object"
  value = {
    rolearn  = aws_iam_role.this.arn
    username = local.name
    groups   = [local.name]
  }
}
