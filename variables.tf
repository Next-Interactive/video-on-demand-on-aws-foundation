variable "domain_name" {
  type    = string
  default = "nextradiotv.com"
}

variable "environment" {
  type    = string
  default = "sandbox"
}

variable "application" {
  type    = string
  default = "ftps"
}

variable "username" {
  type    = string
  default = "habid"
}

variable "email_to_notify" {
  type    = string
  default = "hicham.abid.prestataire@alticemedia.com"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0267b9b35cead61f6"
}