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
    install = optional(bool, true)
    destroy = optional(bool, false)
    version = string
    aws_auth_roles = optional(list(object({
      username = string,
      rolearn  = string,
      groups   = list(string),
    })), [])
    subnet_ids  = list(string)
    vpc_id      = string
    enable_rbac = optional(bool, true)
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
  IRSA support for related DNS services.
  EOT

  type = object({
    hosted_zone_ids = list(string)
    service_accounts = optional(object({
      external_dns = optional(list(string))
      cert_manager = optional(list(string))
    }))
  })

  default = {
    hosted_zone_ids = [],
    service_accounts = {
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
    install = optional(bool, true)
    git = object({
      name            = optional(string, "platform-system-init"),
      url             = string,
      path            = string,
      known_hosts     = list(string)
      create_ssh_key  = optional(bool, true)
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
  description = <<EOT
    Configures velero and the velero bucket. An external velero bucket that 
    is managed externally from this module can be passed in via 
    `config_bucket = {existing_id = "123"}`. If `config_bucket = {enable = true}` 
    even with `install = false` the bucket will remain created.
  EOT

  type = object({
    existing_id = optional(string)
    enable      = optional(bool, true)
    server_side_encryption_configuration = optional(object({
      type              = optional(string, "aws:kms")
      kms_master_key_id = optional(string)
      alias             = optional(string)
    }), {})

    service_accounts = optional(object({
      velero = optional(list(string), ["velero:velero"])
    }))
  })

  default = {}


  validation {
    condition = anytrue([
      // If enabled, with existing bucket and kms is used. The alias or kms id needs to be passed in
      alltrue([
        var.config_velero.enable,
        var.config_velero.existing_id != null,
        try(var.config_velero.server_side_encryption_configuration.type, "aws:kms") != "AES256",
        (
          try(var.config_velero.server_side_encryption_configuration.kms_master_key_id, null) != null
          || try(var.config_velero.server_side_encryption_configuration.alias, null) != null
        )
      ]),
      // If enabled but not kms, ok
      var.config_velero.enable && try(var.config_velero.server_side_encryption_configuration.type, "aws:kms") == "AES256",
      // If enabled and exisiting bucket is null, default kms takes over
      var.config_velero.enable && var.config_velero.existing_id == null,
      // If not enabled
      !var.config_velero.enable
    ])
    error_message = "Existing bucket with aws:kms encryption needs a kms key or alias passed in."
  }
}

variable "config_karpenter" {
  description = <<EOT
    Karpenter configuration. Karpenter does not handle cleaning itself up gracefully. We 
    attempt to fix this by using a local-exec to wait, but this is not garunteed to work.
    
    Includes:
    - install: Will install the karpenter operator
    - enable_provisioners: Will include the default helm release of the platform-system provisioner CR.
  EOT
  type = object({
    install             = optional(bool, true)
    enable_provisioners = optional(bool, true)
  })

  default = {}
}
