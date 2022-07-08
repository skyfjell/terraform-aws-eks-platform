module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.1"

  create                   = local.cluster.install
  cluster_name             = local.labels.id
  cluster_version          = local.cluster.version
  enable_irsa              = true
  iam_role_use_name_prefix = false


  vpc_id     = local.cluster.vpc_id
  subnet_ids = local.cluster.subnet_ids

  eks_managed_node_groups = local.cluster.install ? {
    default = {
      instance_types                        = ["t3.medium"]
      create_security_group                 = false
      attach_cluster_primary_security_group = true

      min_size     = 1
      max_size     = 1
      desired_size = 1

      iam_role_additional_policies = [
        # Required by Karpenter
        "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      taints = [
        {
          "key" : "CriticalAddonsOnly",
          "value" : "true",
          "effect" : "NO_SCHEDULE"
        }
      ]
    }
  } : {}

  eks_managed_node_group_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  manage_aws_auth_configmap = local.cluster.install

  aws_auth_roles = flatten(concat(
    [
      for role in [
        module.platform_edit_iam[*].aws_auth_role,
        module.platform_view_iam[*].aws_auth_role,
      ] : role if role != null
    ],
    local.cluster.aws_auth_roles
  ))

  tags = merge(
    local.labels.tags,
    {
      "karpenter.sh/discovery" = local.labels.id
    },
  )
}

data "aws_eks_cluster" "this" {
  count = local.cluster.destroy ? 1 : 0

  name = local.labels.id
}

data "aws_eks_cluster_auth" "this" {
  count = local.cluster.destroy ? 1 : 0

  name = local.labels.id
}
