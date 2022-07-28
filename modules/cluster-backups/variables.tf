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
    id     = optional(string)
    enable = optional(bool)
    server_side_encryption_configuration = optional(object({
      type              = optional(string)
      kms_master_key_id = optional(string)
      alias             = optional(string)
    }))
  })
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
