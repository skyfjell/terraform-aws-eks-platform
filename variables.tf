variable "labels" {
  description = "Instance of labels module"
  type = object(
    {
      id   = string
      tags = any
    }
  )
}

variable "users" {
  description = "Map of lists of user ARNs"

  type = object({
    edit = optional(list(string)),
    view = optional(list(string)),
  })
}

variable "cluster" {
  description = "Cluster Configuration"

  type = object({
    install = bool
    version = string
    aws_auth_roles = optional(list(object({
      username = string,
      rolearn  = string,
      groups   = list(string),
    })))
    subnet_ids = list(string)
    vpc_id     = string
  })
}

variable "managed_node_groups" {
  description = "EKS Managed Node Groups"
  type        = map(object({}))
  default     = {}
}

variable "domain_zones" {
  description = "ExternalDNS Managed Domains"

  type = list(object(
    {
      zone_id = string
      domain  = string
    }
  ))

  default = []
}

variable "config_autoscaler" {
  description = "Cluster Autoscaler Configuration"
  type = object({
    enable_service_account = bool
    namespace              = string
  })

  default = {
    enable_service_account = false
    namespace              = "autoscaler"
  }
}

variable "config_flux" {
  description = "Flux Configuration"

  type = object({
    install = bool
    git = object({
      name            = string,
      url             = string,
      path            = string,
      known_hosts     = list(string)
      create_ssh_key  = optional(bool)
      existing_secret = optional(string)
      ref = object({
        branch = optional(string)
        commit = optional(string)
        tag    = optional(string)
        semver = optional(string)
      }),
    })
  })
}

variable "config_velero" {
  description = "Velero Configuration"

  type = object({
    install          = optional(bool)
    version          = optional(string)
    bucket           = optional(string)
    service_accounts = optional(list(string))
  })

  default = {
    install = true
    version = "2.30.1"
  }
}
variable "config_karpenter" {
  description = "Karpenter Configuration"

  type = object({
    install = bool
  })

  default = {
    install = true
  }
}
