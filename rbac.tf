locals {
  rbac_labels = {
    "app.kubernetes.io/managed-by"          = "Terraform"
    "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform"
    "app.kubernetes.io/created-by-instance" = local.labels.id
    "app.kubernetes.io/part-of"             = "platform"
    "app.kubernetes.io/component"           = "aws-access"
  }

  rbac_manifests_map = {

    cluster_roles = {
      karpenter_edit = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "karpenter-edit"
          labels = merge(local.rbac_labels, { "rbac.authorization.k8s.io/aggregate-to-platform-edit" = "true" })
        }
        rules = [{
          apiGroups = ["karpenter.sh"]
          resources = ["*"]
          verbs     = ["create", "delete", "deletecollection", "patch", "update"]
        }]
      },
      karpenter_view = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "karpenter-view"
          labels = merge(local.rbac_labels, { "rbac.authorization.k8s.io/aggregate-to-platform-view" = "true" })
        }
        rules = [{
          apiGroups = ["karpenter.sh"]
          resources = ["*"]
          verbs     = ["get", "list", "watch"]
        }]
      },
      platform_view = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"
        aggregationRule = {
          clusterRoleSelectors = [
            {
              matchLabels = {
                "rbac.authorization.k8s.io/aggregate-to-view" = "true"
              }
            },
          ]
        }
        metadata = {
          name = "platform-view"
          annotations = {
            "rbac.authorization.kubernetes.io/autoupdate" = "true"
          }
          labels = merge(local.rbac_labels, { "rbac.authorization.k8s.io/aggregate-to-platform-edit" = "true" })
        }
        rules = []
      }

      platform_edit_aggregate = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "platform-edit-aggregate"
          labels = merge(local.rbac_labels, { "rbac.authorization.k8s.io/aggregate-to-platform-edit" = "true" })
        }
        rules = [{
          apiGroups = [""]
          resources = ["nodes"]
          verbs     = ["get", "list", "watch"]
        }]
      }
      platform_edit = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"
        aggregationRule = {
          clusterRoleSelectors = [
            {
              matchLabels = {
                "rbac.authorization.k8s.io/aggregate-to-edit" = "true"
              }
            },
            {
              matchLabels = {
                "rbac.authorization.k8s.io/aggregate-to-platform-edit" = "true"
              }
            }
          ]
        }
        metadata = {
          name = "platform-edit"
          annotations = {
            "rbac.authorization.kubernetes.io/autoupdate" = "true"
          }
          labels = local.rbac_labels
        }
        rules = []
      }
    },

    cluster_role_bindings = {
      cluster-role-binding-platform-view = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRoleBinding"
        metadata = {
          name = "platform-view"
        }
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io"
          kind     = "ClusterRole"
          name     = "platform-view"
        }
        subjects = [
          {
            apiGroup = "rbac.authorization.k8s.io"
            kind     = "Group"
            name     = "platform-view"
          }
        ]
      },

      cluster-role-binding-platform-edit = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRoleBinding"
        metadata = {
          name = "platform-edit"
        }
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io"
          kind     = "ClusterRole"
          name     = "platform-edit"
        }
        subjects = [
          {
            apiGroup = "rbac.authorization.k8s.io"
            kind     = "Group"
            name     = "platform-edit"
          }
        ]
      },
    }

  }
}

locals {
  rbac_manifests = concat(
    values(local.rbac_manifests_map.cluster_roles),
    values(local.rbac_manifests_map.cluster_role_bindings)
  )
}

# TODO: Refactor to use proper kubernetes_[resource] resources.
resource "helm_release" "rbac" {
  count      = local.cluster.install && local.config_karpenter.install ? 1 : 0
  name       = "rbac"
  repository = "https://skyfjell.github.io/charts"
  chart      = "null"
  values     = [yamlencode({ manifests = local.rbac_manifests })]

}
