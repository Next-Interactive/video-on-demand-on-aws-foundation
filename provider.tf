provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::890507559531:role/sandbox-fullaccess-iam-role"
  }
  region = local.region
}

provider "aws" {
  alias  = "root"
  region = local.region
}