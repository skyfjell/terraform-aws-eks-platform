variable "user_arns" {
  description = "List of user arns that will be allowed to assume role."
  type        = list(string)
  default     = []
}

variable "name" {
  description = "Name prefix used for resources."
  type        = string
}

variable "labels" {
  description = "Instance of labels module"
  type = object(
    {
      id   = string
      tags = any
    }
  )
}

variable "max_session_duration" {
  description = "Max role assumption duration in seconds"
  type        = number
  default     = 14400
}

variable "actions" {
  description = "List of policy actions this role is allowed to perform on the cluster"
  type        = list(string)
  default     = []
}

variable "cluster_arn" {
  description = "Cluster arn"
  type        = string
}

variable "attach" {
  description = "Create and attach cluster arn policies, used in staged builds."
  type        = bool
}
