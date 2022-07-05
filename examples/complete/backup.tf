# module "backups_bucket" {

#   source  = "skyfjell/s3/aws"
#   version = "1.0.1"

#   use_prefix    = false
#   name          = "velero-backup"
#   logging       = null
#   sse_algorithm = "AES256"

#   labels = module.labels

# }
