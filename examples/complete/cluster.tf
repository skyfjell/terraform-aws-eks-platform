locals {
  sub_map = {
    "2a" = 0
    "2b" = 1
    "2c" = 2
  }
  subnet_ids = slice(module.vpc.private_subnets, 3, 6)
  // Node group where subnet ids don't matter, pass in all the subnet ids
  all_node_groups = { for name, val in local.node_groups : name => merge(val["spec"], { subnet_ids = local.subnet_ids }) if contains(val["subnets"], "all") }
  // AZ specific node groups. Iterate over the subnets and construct an object with a unique name "apps-2b" from the AZ and 
  azs_node_groups = [for name, val in local.node_groups : {
    for sid in val["subnets"] : "${name}-${sid}" => merge(val["spec"], { subnet_ids = [local.subnet_ids[local.sub_map[sid]]] })
    } if !contains(val["subnets"], "all")
  ]
}

module "example-complete" {
  source = "../../"

  cluster = {
    install = true
    # destroy    = "inf-stage-test-ex-cluster"
    version    = "1.22"
    subnet_ids = local.subnet_ids
    vpc_id     = module.vpc.vpc_id
  }

  config_flux = {
    git = {
      url  = "ssh://git@github.com/skyfjell/examples.git"
      path = "clusters/example"
      name = "ssh"
      ref  = { branch = "main" }
      known_hosts = [
        "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
      ]
      create_ssh_key = false
    }
  }
  labels = module.labels

  users = {
    edit = [aws_iam_user.test_edit.arn]
    view = [aws_iam_user.test_view.arn]
  }

  config_velero = {
    install = false
    version = "2.29.5"
  }

}

# provider "kubernetes" {
#   alias = "ops-prod"

#   host                   = element(concat(data.aws_eks_cluster.ops-prod.*.endpoint, [""]), 0)
#   cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.ops-prod.*.certificate_authority.0.data, [""]), 0))
#   token                  = element(concat(data.aws_eks_cluster_auth.ops-prod.*.token, [""]), 0)

#   experiments {
#     manifest_resource = true
#   }
# }

locals {
  cluster_module = module.example-complete.cluster
}


provider "kubernetes" {
  host                   = local.cluster_module.endpoint
  cluster_ca_certificate = base64decode(local.cluster_module.certificate_authority_data)
  token                  = local.cluster_module.token

  dynamic "exec" {
    for_each = local.cluster_module.destroy ? [] : [1]
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", local.cluster_module.id]
    }
  }
}

provider "kubectl" {
  load_config_file = false

  host                   = local.cluster_module.endpoint
  cluster_ca_certificate = base64decode(local.cluster_module.certificate_authority_data)
  token                  = local.cluster_module.token

  dynamic "exec" {
    for_each = local.cluster_module.destroy ? [] : [1]
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", local.cluster_module.id]
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_module.endpoint
    cluster_ca_certificate = base64decode(local.cluster_module.certificate_authority_data)
    token                  = local.cluster_module.token

    dynamic "exec" {
      for_each = local.cluster_module.destroy ? [] : [1]
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        # This requires the awscli to be installed locally where Terraform is executed
        args = ["eks", "get-token", "--cluster-name", local.cluster_module.id]
      }
    }
  }
}
