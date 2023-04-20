terraform {
  backend "s3" {
    bucket         = "next-terraform-backend"
    dynamodb_table = "terraform-state-lock-dynamo"
    key            = "workspace-tf-kantar-watermarking/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
