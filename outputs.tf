output "assume_policy" {
  description = "OIDC Assume Role Policy"
  value       = data.aws_iam_policy_document.eks_assume_role_policy
}

output "cluster" {
  description = "Cluster Properties"
  value = {
    id = try(
      module.cluster.cluster_id,
      null
    ),
    destroy = local.cluster.destroy,
    arn = try(
      local.cluster.destroy ? one(data.aws_eks_cluster.this.*.arn) : module.cluster.cluster_arn,
      null
    ),
    endpoint = try(
      local.cluster.destroy ? one(data.aws_eks_cluster.this.*.endpoint) : module.cluster.cluster_endpoint,
      null
    ),
    certificate_authority_data = try(
      local.cluster.destroy ? one(data.aws_eks_cluster.this.*.certificate_authority.0.data) : module.cluster.cluster_certificate_authority_data,
      null
    ),
    token = try(
      one(data.aws_eks_cluster_auth.this.*.token),
      null
    )
    oidc_provider = try(module.cluster.oidc_provider, ""),
  }
}

output "flux" {
  description = "Flux Properties"
  value = {
    ssh_key = one(module.flux_git_repository.*.ssh_key)
  }
}

output "velero_storage" {
  description = "Velero Bucket Properties"
  value       = one(module.velero.*.s3)
}

output "cluster_roles" {
  description = "Cluster Role ARNs"
  value = local.cluster.install ? {
    edit = one(module.platform_edit_iam[*].role.arn)
    view = one(module.platform_view_iam[*].role.arn)
  } : {}
}
