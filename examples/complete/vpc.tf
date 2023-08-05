module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 4.0.0, < 5.0.0"

  name = module.labels.id

  azs = data.aws_availability_zones.available.names

  cidr                 = local.cidr
  public_subnets       = local.public_subnets
  private_subnets      = local.private_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  vpc_tags = module.labels.tags
  tags     = module.labels.tags
  private_subnet_tags = {
    "kubernetes.io/cluster/${module.labels.id}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "karpenter.sh/discovery"                    = module.labels.id
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${module.labels.id}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_route53_zone" "primary" {
  name = "tftest.skyfjell.io"

  tags = module.labels.tags
}
