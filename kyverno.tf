resource "helm_release" "kyverno" {
  count = local.cluster.install && local.config_kyverno.install ? 1 : 0

  namespace        = "kyverno"
  create_namespace = true

  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "v2.5.1"

  values = [yamlencode({
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    }]
  })]

}

locals {
  # This is the only required policy at this time 
  # to ensure karpenter is bound by node selectors
  policy_manifests = {
    "apiVersion" = "kyverno.io/v1"
    "kind"       = "ClusterPolicy"
    "metadata" = {
      "annotations" = {
        "policies.kyverno.io/description" = "Require nodeSelector to be set with the format `spec`: `<value>` to match an existing Karpenter spec for auto scaling."
        "policies.kyverno.io/subject"     = "Pod, nodeSelector"
        "policies.kyverno.io/title"       = "Require nodeSelector for all Pods"
      }
      "name" = "require-pod-node-selector"
    }
    "spec" = {
      "rules" = [
        {
          "match" = {
            "any" = [
              {
                "resources" = {
                  "kinds" = [
                    "Pod",
                  ]
                }
              },
            ]
          }
          "exclude" = {
            "any" = [
              {
                "resources" = {
                  "selector" = {
                    "matchLabels" = {
                      "app.kubernetes.io/name" = "karpenter"
                    }
                  }
                }
              },
            ]
          }
          "name" = "require-pod-node-selector"
          "validate" = {
            "message" = "nodeSelector is required"
            "pattern" = {
              "spec" = {
                "nodeSelector" = {
                  "spec" = "?*"
                }
              }
            }
          }
        },
      ]
      "validationFailureAction" = "enforce"
    }
  }
}


resource "helm_release" "kyverno-custom-policies" {
  count = local.cluster.install && local.config_kyverno.install ? 1 : 0

  name       = "kyverno-custom-policies" 
  repository = "https://skyfjell.github.io/charts"
  chart      = "null"
  values     = [yamlencode({ manifests = [local.policy_manifests]})]
  
  depends_on = [ helm_release.kyverno ]
}
