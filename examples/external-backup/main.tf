module "labels" {
  source  = "skyfjell/label/null"
  version = "1.0.2"

  environment = "stage"
  name        = "ex"
  project     = "test"
  tenant      = "inf"

  config_labels = {
    enable_empty = true
  }

  config_unique_id = {
    enable        = false
    enable_suffix = false
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
