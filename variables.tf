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
    install = optional(bool)
    destroy = optional(bool)
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

variable "config_dns" {
  description = <<EOT
  Configuration of DNS. Support for a list of existing domain zones and
  IRSA support for related DNS actions. Includes cert-manager configuration
  for route53 challenges.
  EOT

  type = object({
    domain_zones = list(object(
      {
        zone_id = string
        domain  = string
      }
    ))
    irsa = optional(object({
      external_dns = optional(list(string))
      cert_manager = optional(list(string))
    }))
  })

  default = {
    domain_zones = [],
    irsa = {
      external_dns = ["external-dns:external-dns"]
      cert_manager = ["cert-manager:cert-manager"]
    }
  }
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
    install = optional(bool)
    git = object({
      name            = string,
      url             = string,
      path            = string,
      known_hosts     = list(string)
      create_ssh_key  = optional(bool)
      existing_secret = optional(string)
      random_suffix   = optional(bool)
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
  description = <<EOT
    Configures velero and the velero bucket. An external velero bucket that 
    is managed externally from this module can be passed in via 
    `config_bucket = {id = "123"}`. If `config_bucket = {enable = true}` 
    even with `install = false` the bucket will remain created.
  EOT

  type = object({
    install = optional(bool)
    version = optional(string)
    config_bucket = optional(object({
      existing_id = optional(string)
      enable      = optional(bool)
      server_side_encryption_configuration = optional(object({
        type              = optional(string)
        kms_master_key_id = optional(string)
        alias             = optional(string)
      }))
    }))
    service_accounts = optional(list(string))
  })

  default = {
    install = true
    version = "2.30.1"
    config_bucket = {
      enable = true
      server_side_encryption_configuration = {
        type = "aws:kms"
      }
    }
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
