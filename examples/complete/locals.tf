locals {
  cidr            = var.cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  node_groups     = var.node_groups
  valid_groups    = concat(["admins", "users"], [for k in var.groups : k.name])
}

locals {
  users = [for x in var.users : {
    name   = x.name
    groups = [for y in x.groups : y if contains(local.valid_groups, y)]
  }]
  groups = [for x in var.groups : { name = x.name }]
}
