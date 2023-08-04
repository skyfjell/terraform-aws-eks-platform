terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = ">= 0.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.1.0, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.2.0, < 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0, < 6.0.0"
    }
    awsutils = {
      source  = "cloudposse/awsutils"
      version = ">= 0.11.0, < 1.0.0"
    }
  }
}
