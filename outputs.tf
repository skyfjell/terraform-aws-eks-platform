output "assume_policy" {
  value       = data.aws_iam_policy_document.eks_assume_role_policy
  description = "Commonly used oidc assume role policy"
}

output "cluster" {
  description = "Ouput from terraform-aws-eks cluster module"
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

output "velero" {
  value = {
    s3 = try(one(module.velero_bucket.*.s3))
  }
  description = "Outputs from configuring velero"
}

output "cluster_roles" {
  value = local.cluster.install ? {
    edit = one(module.platform_edit_iam[*].role.arn)
    view = one(module.platform_view_iam[*].role.arn)
  } : {}
}

output "flux" {
  description = "Object with flux information."
  value = {
    ssh_key   = local.config_flux.install ? module.flux_git_repository.0.ssh_key : null
    namespace = local.config_flux.install ? module.flux_git_repository.0.namespace : null
  }
}

