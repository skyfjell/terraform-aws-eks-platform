variable "oidc_id" {
  description = "Cluster OIDC"
  type        = string
}

variable "cluster_id" {
  type = string
}

variable "config_bucket" {
  description = "Backup S3 bucket configuration, pass through to bucket module."
  type = object({
    existing_id = optional(list(string))
    enable      = optional(bool)
    server_side_encryption_configuration = optional(object({
      type              = optional(string)
      kms_master_key_id = optional(string)
      alias             = optional(string)
    }))
  })

  # validation {
  #   condition = anytrue([
  #     // If enabled, with existing bucket and kms is used. The alias or kms id needs to be passed in
  #     alltrue([
  #       var.config_bucket.enable,
  #       var.config_bucket.existing_id != null,
  #       try(var.config_bucket.server_side_encryption_configuration.type, "aws:kms") != "AES256",
  #       (
  #         try(var.config_bucket.server_side_encryption_configuration.kms_master_key_id, null) != null
  #         || try(var.config_bucket.server_side_encryption_configuration.alias, null) != null
  #       )
  #     ]),
  #     // If enabled but not kms, ok
  #     var.config_bucket.enable && try(var.config_bucket.server_side_encryption_configuration.type, "aws:kms") == "AES256",
  #     // If enabled and exisiting bucket is null, default kms takes over
  #     var.config_bucket.enable && var.config_bucket.existing_id == null,
  #     // If not enabled
  #     !var.config_bucket.enable
  #   ])
  #   error_message = "Existing bucket with aws:kms encryption needs a kms key or alias passed in."
  # }
}

variable "velero_version" {
  type        = string
  description = "Velero version"
}

variable "labels" {
  type = object({
    id   = string
    tags = any
  })
}

variable "install" {
  type    = bool
  default = true
}
