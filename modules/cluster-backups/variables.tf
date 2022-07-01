variable "oidc_id" {
  description = "Cluster OIDC"
  type        = string
}

variable "cluster_id" {
  type = string
}

variable "bucket_id" {
  description = "AWS S3 bucket id"
  type        = string
  default     = null
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
