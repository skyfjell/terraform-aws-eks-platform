locals {
  // Karpenter needs to be up so flux gets a node group
  install_flux = local.cluster.install && local.config_flux.install && local.config_karpenter.install
}

module "flux_install" {
  count = local.install_flux ? 1 : 0

  source  = "skyfjell/install/flux"
  version = "1.0.5"

  name = local.labels.id

  node_selector = { "skyfjell.io/node-selector" : "platform-system" }
  chart_version = local.config_flux.chart_version

  depends_on = [
    helm_release.karpenter_provisioners,
    null_resource.wait_for_scaledown
  ]
}

module "flux_git_repository" {
  count = local.install_flux ? 1 : 0

  source  = "skyfjell/git-repository/flux"
  version = "1.0.3"

  url             = local.config_flux.git.url
  interval        = "1m"
  known_hosts     = local.config_flux.git.known_hosts
  ref             = local.config_flux.git.ref
  name            = local.config_flux.git.name
  create_ssh_key  = local.config_flux.git.create_ssh_key
  existing_secret = local.config_flux.git.existing_secret

  depends_on = [module.flux_install]
}

module "flux_kustomization" {
  count = local.install_flux ? 1 : 0

  source  = "skyfjell/kustomization/flux"
  version = "1.0.4"

  name = local.config_flux.git.name
  path = local.config_flux.git.path

  depends_on = [module.flux_git_repository]
}
