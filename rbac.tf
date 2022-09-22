locals {
  rbac_labels = {
    "app.kubernetes.io/managed-by"          = "Terraform"
    "app.kubernetes.io/created-by"          = "terraform-aws-eks-platform"
    "app.kubernetes.io/created-by-instance" = local.labels.id
    "app.kubernetes.io/part-of"             = "platform"
    "app.kubernetes.io/component"           = "aws-access"
  }

  rbac_tf = {
    enable_karpenter = local.cluster.install && local.config_karpenter.install
    enable_flux      = local.cluster.install && local.config_flux.install

    cluster_roles = {
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
            {
              matchLabels = {
                "rbac.skyfjell.io/aggregate-to-platform-view" = "true"
              }
            }
          ]
        }
        metadata = {
          name = "platform-view"
          annotations = {
            "rbac.authorization.kubernetes.io/autoupdate" = "true"
          }
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-edit" = "true" })
        }
        rules = []
      }
      platform_view_aggregate = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"
        metadata = {
          name = "platform-view-aggregate"
          annotations = {
            "rbac.authorization.kubernetes.io/autoupdate" = "true"
          }
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-view" = "true" })
        }
        rules = [
          {
            apiGroups = ["apiextensions.k8s.io"]
            resources = ["customresourcedefinitions"]
            verbs     = ["get", "list", "watch"]
          }
        ]
      },

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
                "rbac.skyfjell.io/aggregate-to-platform-edit" = "true"
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
    platform_edit_aggregate = {
      apiVersion = "rbac.authorization.k8s.io/v1"
      kind       = "ClusterRole"

      metadata = {
        name   = "platform-edit-aggregate"
        labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-edit" = "true" })
      }
      rules = [{
        apiGroups = [""]
        resources = ["nodes"]
        verbs     = ["get", "list", "watch"]
      }]
    },

    cluster_role_bindings = {
      platform-view = {
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

      platform-edit = {
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

    karpenter_cluster_roles = {
      view = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "karpenter-view"
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-view" = "true" })
        }
        rules = [{
          apiGroups = ["karpenter.sh"]
          resources = ["provisioners", "provisioners/status"]
          verbs     = ["get", "list", "watch"]
        }]
      },
      edit = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "karpenter-edit"
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-edit" = "true" })
        }
        rules = [{
          apiGroups = ["karpenter.sh"]
          resources = ["provisioners", "provisioners/status"]
          verbs     = ["create", "delete", "deletecollection", "patch", "update"]
        }]
      },
    },

    flux_cluster_roles = {
      view = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "flux-view"
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-view" = "true" })
        }
        rules = [{
          apiGroups = [
            "helm.toolkit.fluxcd.io",
            "image.toolkit.fluxcd.io",
            "kustomize.toolkit.fluxcd.io",
            "notification.toolkit.fluxcd.io",
            "source.toolkit.fluxcd.io",
          ],
          resources = ["*"],
          verbs     = ["get", "list", "watch"],
        }]
      },
      edit = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind       = "ClusterRole"

        metadata = {
          name   = "flux-edit"
          labels = merge(local.rbac_labels, { "rbac.skyfjell.io/aggregate-to-platform-edit" = "true" })
        }
        rules = [{
          apiGroups = [
            "helm.toolkit.fluxcd.io",
            "image.toolkit.fluxcd.io",
            "kustomize.toolkit.fluxcd.io",
            "notification.toolkit.fluxcd.io",
            "source.toolkit.fluxcd.io",
          ],
          resources = ["*"],
          verbs     = ["create", "delete", "deletecollection", "patch", "update"],
        }]
      },

    }
  }
}

locals {
  rbac_manifests = concat(
    values(local.rbac_tf.cluster_roles),
    values(local.rbac_tf.cluster_role_bindings),
    local.rbac_tf.enable_flux ? values(local.rbac_tf.flux_cluster_roles) : [],
    local.rbac_tf.enable_karpenter ? values(local.rbac_tf.karpenter_cluster_roles) : [],
  )
}

# TODO: Refactor to use proper kubernetes_[resource] resources.
resource "helm_release" "rbac" {
  count      = local.cluster.install ? 1 : 0
  name       = "rbac"
  repository = "https://skyfjell.github.io/charts"
  chart      = "null"
  values     = [yamlencode({ manifests = local.rbac_manifests })]

  depends_on = [
    module.cluster
  ]

}
