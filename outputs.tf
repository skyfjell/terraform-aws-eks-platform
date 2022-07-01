output "assume_policy" {
  value       = data.aws_iam_policy_document.eks_assume_role_policy
  description = "Commonly used oidc assume role policy"
}

output "cluster" {
  description = "Ouput from terraform-aws-eks cluster module"
  value = {
    cluster_id                         = try(module.cluster.cluster_id, ""),
    cluster_arn                        = try(module.cluster.cluster_arn, ""),
    cluster_endpoint                   = try(module.cluster.cluster_endpoint, ""),
    cluster_certificate_authority_data = try(module.cluster.cluster_certificate_authority_data, ""),
    oidc_provider                      = try(module.cluster.oidc_provider, ""),
  }
}

output "velero_storage" {
  value       = local.config_velero.install ? module.velero[0].s3 : null
  description = "S3 object with `id` and `arn` for velero storage bucket. If velero isn't used, will be null"
}

output "cluster_roles" {
  value = local.cluster.install ? {
    edit = module.platform_edit_iam.role.arn
    view = module.platform_view_iam.role.arn
  } : {}
}
