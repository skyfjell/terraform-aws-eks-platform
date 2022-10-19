# locals {
#   provisioners = [
#     {
#       apiVersion = "karpenter.sh/v1alpha5"
#       kind       = "Provisioner"
#       metadata = {
#         name   = "platform-system"
#         labels = merge({ for key in keys(local.labels.tags) : key => tostring(local.labels.tags[key]) }, { "skyfjell.io/node-selector" = "platform-system" })
#       }

#       spec = {
#         labels = { "skyfjell.io/node-selector" = "platform-system" }

#         requirements = [
#           {
#             key      = "node.kubernetes.io/instance-type"
#             operator = "In"
#             #   TODO: module variable
#             values = ["t3.large"]
#           }
#         ]

#         provider = {
#           subnetSelector = {
#             "karpenter.sh/discovery" = local.labels.id
#           }
#           securityGroupSelector = {
#             "karpenter.sh/discovery" = local.labels.id
#           }
#           tags = {
#             "karpenter.sh/discovery" = local.labels.id
#           }
#         }

#         ttlSecondsAfterEmpty = 60
#       }
#     }
#   ]
# }

# resource "helm_release" "karpenter_provisioners" {
#   count = local.cluster.install && local.config_karpenter.install ? 1 : 0

#   name       = "karpenter-provisioners"
#   namespace  = "karpenter"
#   repository = "https://skyfjell.github.io/charts"
#   chart      = "null"
#   values     = [yamlencode({ manifests = local.provisioners })]

#   depends_on = [
#     aws_iam_instance_profile.karpenter,
#     module.karpenter_irsa,
#     helm_release.karpenter,
#   ]
# }


# locals {
#   wait_command = <<EOT
#     while [[ $( \
#       aws ec2 describe-instances \
#       --region ${data.aws_region.current.name} \
#       --query "Reservations[*].Instances[*].{InstanceId: InstanceId, State: State.Name}" \
#       --filters "Name=tag-key,Values=karpenter.sh/provisioner-name" "Name=tag-key,Values=kubernetes.io/cluster/${local.labels.id}" \
#       | jq '. | flatten | map(select(.State != "terminated")) | length' \
#       ) != 0 \
#     ]];
#     do
#       sleep 5;
#     done;

#     sleep 3;
#   EOT
# }

# locals {
#   cmd = local.cluster.install && local.config_karpenter.install ? { "${local.wait_command}" : null } : {}
# }

# resource "null_resource" "wait_for_scaledown" {
#   for_each = local.cmd

#   provisioner "local-exec" {
#     when        = destroy
#     interpreter = ["bash", "-c"]
#     command     = each.key
#   }

#   depends_on = [
#     helm_release.karpenter_provisioners
#   ]
# }
