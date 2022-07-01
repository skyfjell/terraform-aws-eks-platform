provider "aws" {
  region = "us-east-2"
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}


provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

provider "awsutils" {
  region = "us-east-2"
}
