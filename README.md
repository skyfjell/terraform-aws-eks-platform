# Terraform AWS EKS Platform Module

Gracefully set up(and tear down) EKS clusters with optional enhancements such as [Karpenter](https://karpenter.sh/)(Node Automation), [Flux](https://fluxcd.io/)(GitOps CD), [Velero](https://velero.io/)(Backups).

## ⚠️ Troubleshooting ⚠️

### Destruction

In order to properly destroy the cluster, you must set `install = false` and `destroy = true`.

This toggles the output for auth from the cluster resource output to `aws_eks_cluster` and `aws_eks_cluster_auth` data sources.

### `Error: error reading EKS Cluster (<...>): couldn't find resource`

If the cluster has been destroyed, but the run errored out and needed to be re-applied, unset the `destroy` flag or set to false.

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0, <= 5.0.0 |
| <a name="requirement_awsutils"></a> [awsutils](#requirement\_awsutils) | >= 0.11.0, < 1.0.0 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | >= 0.12.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.2.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.1.0, < 3.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.31.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.6.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.13.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cert_manager_irsa"></a> [cert\_manager\_irsa](#module\_cert\_manager\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.4.0 |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | terraform-aws-modules/eks/aws | 18.29.0 |
| <a name="module_ebs_csi_irsa_role"></a> [ebs\_csi\_irsa\_role](#module\_ebs\_csi\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.4.0 |
| <a name="module_external_dns_irsa"></a> [external\_dns\_irsa](#module\_external\_dns\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.4.0 |
| <a name="module_flux_git_repository"></a> [flux\_git\_repository](#module\_flux\_git\_repository) | skyfjell/git-repository/flux | 1.0.3 |
| <a name="module_flux_install"></a> [flux\_install](#module\_flux\_install) | skyfjell/install/flux | 1.0.4 |
| <a name="module_flux_kustomization"></a> [flux\_kustomization](#module\_flux\_kustomization) | skyfjell/kustomization/flux | 1.0.3 |
| <a name="module_karpenter_irsa"></a> [karpenter\_irsa](#module\_karpenter\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.4.0 |
| <a name="module_platform_edit_iam"></a> [platform\_edit\_iam](#module\_platform\_edit\_iam) | ./modules/cluster-iam | n/a |
| <a name="module_platform_view_iam"></a> [platform\_view\_iam](#module\_platform\_view\_iam) | ./modules/cluster-iam | n/a |
| <a name="module_velero_bucket"></a> [velero\_bucket](#module\_velero\_bucket) | skyfjell/s3/aws | 1.0.6 |
| <a name="module_velero_irsa"></a> [velero\_irsa](#module\_velero\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.velero_irsa_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_oidc_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.velero_irsa_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_provisioners](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.rbac](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.wait_for_scaledown](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.autoscaler_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.velero_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster Configuration | <pre>object({<br>    install = optional(bool, true)<br>    destroy = optional(bool, false)<br>    version = string<br>    aws_auth_roles = optional(list(object({<br>      username = string,<br>      rolearn  = string,<br>      groups   = list(string),<br>    })), [])<br>    subnet_ids = list(string)<br>    vpc_id     = string<br>  })</pre> | n/a | yes |
| <a name="input_config_autoscaler"></a> [config\_autoscaler](#input\_config\_autoscaler) | Cluster Autoscaler Configuration | <pre>object({<br>    enable_service_account = bool<br>    namespace              = string<br>  })</pre> | <pre>{<br>  "enable_service_account": false,<br>  "namespace": "autoscaler"<br>}</pre> | no |
| <a name="input_config_dns"></a> [config\_dns](#input\_config\_dns) | Configuration of DNS. Support for a list of existing domain zones and<br>  IRSA support for related DNS services. | <pre>object({<br>    hosted_zone_ids = list(string)<br>    service_accounts = optional(object({<br>      external_dns = optional(list(string))<br>      cert_manager = optional(list(string))<br>    }))<br>  })</pre> | <pre>{<br>  "hosted_zone_ids": [],<br>  "service_accounts": {<br>    "cert_manager": [<br>      "cert-manager:cert-manager"<br>    ],<br>    "external_dns": [<br>      "external-dns:external-dns"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_config_flux"></a> [config\_flux](#input\_config\_flux) | Flux Configuration | <pre>object({<br>    install = optional(bool, true)<br>    git = object({<br>      name            = optional(string, "platform-system-init"),<br>      url             = string,<br>      path            = string,<br>      known_hosts     = list(string)<br>      create_ssh_key  = optional(bool, true)<br>      existing_secret = optional(string)<br>      ref = object({<br>        branch = optional(string)<br>        commit = optional(string)<br>        tag    = optional(string)<br>        semver = optional(string)<br>      }),<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_config_karpenter"></a> [config\_karpenter](#input\_config\_karpenter) | Karpenter Configuration | <pre>object({<br>    install = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_config_velero"></a> [config\_velero](#input\_config\_velero) | Configures velero and the velero bucket. An external velero bucket that <br>    is managed externally from this module can be passed in via <br>    `config_bucket = {existing_id = "123"}`. If `config_bucket = {enable = true}` <br>    even with `install = false` the bucket will remain created. | <pre>object({<br>    existing_id = optional(string)<br>    enable      = optional(bool)<br>    server_side_encryption_configuration = optional(object({<br>      type              = optional(string)<br>      kms_master_key_id = optional(string)<br>      alias             = optional(string)<br>    }))<br><br>    service_accounts = optional(object({<br>      velero = optional(list(string))<br>    }))<br>  })</pre> | <pre>{<br>  "enable": true,<br>  "server_side_encryption_configuration": {<br>    "type": "aws:kms"<br>  },<br>  "service_accounts": {<br>    "velero": [<br>      "velero:velero"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Instance of labels module | <pre>object(<br>    {<br>      id   = string<br>      tags = any<br>    }<br>  )</pre> | n/a | yes |
| <a name="input_managed_node_groups"></a> [managed\_node\_groups](#input\_managed\_node\_groups) | EKS Managed Node Groups | `map(object({}))` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | Map of lists of user ARNs | <pre>object({<br>    edit = optional(list(string)),<br>    view = optional(list(string)),<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assume_policy"></a> [assume\_policy](#output\_assume\_policy) | Commonly used oidc assume role policy |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Ouput from terraform-aws-eks cluster module |
| <a name="output_cluster_roles"></a> [cluster\_roles](#output\_cluster\_roles) | n/a |
| <a name="output_flux"></a> [flux](#output\_flux) | Object with flux information. |
| <a name="output_velero"></a> [velero](#output\_velero) | Outputs from configuring velero |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
