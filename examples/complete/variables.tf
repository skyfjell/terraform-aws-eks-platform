variable "users" {
  description = "List of users"
  type        = list(any)
}

variable "groups" {
  description = "List of groups"
  type        = list(any)
}

variable "cidr" {
  description = "CIDR address block"
  type        = string
}

variable "private_subnets" {
  description = "List of subnet ip blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of subnet ip blocks"
  type        = list(string)
}

variable "project_env" {
  type        = string
  description = "Name of the project environment"
  default     = "stage"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "wf"
}

variable "node_groups" {
  description = "Node groups for EKS module. Spec key gets passed to terraform-aws-eks module's managed node groups while subnets tell us which AZ to create the subnet in."
  default     = {}
  type = map(object({
    subnets = list(string)
    spec    = any
  }))
  validation {
    condition     = alltrue(flatten([for k, v in var.node_groups : [for s in v["subnets"] : contains(["all", "2a", "2b", "2c"], s)]]))
    error_message = "The key subnets must be either 'all', '2a', '2b' or '2c'."
  }
}
