locals {
  provisioners = [
    {
      apiVersion = "karpenter.sh/v1alpha5"
      kind       = "Provisioner"
      metadata = {
        name   = "system-platform"
        labels = merge({ for key in keys(local.labels.tags) : key => tostring(local.labels.tags[key]) }, { "spec" = "system-platform" })
      }

      spec = {
        labels = { "spec" = "system-platform" }

        requirements = [
          {
            key      = "node.kubernetes.io/instance-type"
            operator = "In"
            #   TODO: module variable
            values = ["t3.large"]
          }
        ]

        provider = {
          subnetSelector = {
            "karpenter.sh/discovery" = local.labels.id
          }
          securityGroupSelector = {
            "karpenter.sh/discovery" = local.labels.id
          }
          tags = {
            "karpenter.sh/discovery" = local.labels.id
          }
        }

        ttlSecondsAfterEmpty = 60
      }
    }
  ]
}

resource "helm_release" "karpenter_provisioners" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  name       = "karpenter-provisioners"
  namespace  = "karpenter"
  repository = "https://skyfjell.github.io/charts"
  chart      = "null"
  values     = [yamlencode({ manifests = local.provisioners })]

  depends_on = [
    helm_release.karpenter,
  ]
}

resource "null_resource" "wait_for_scaledown" {
  count = local.cluster.install && local.config_karpenter.install ? 1 : 0

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "while [[ $(kubectl get nodes --context test -l karpenter.sh/provisioner-name -o json | jq '.items | length') != 0 ]]; do sleep 5; done; sleep 3;"
  }

  depends_on = [
    helm_release.karpenter_provisioners
  ]
}
