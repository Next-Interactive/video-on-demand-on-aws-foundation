data "aws_route53_zone" "main" {
  provider     = aws.root
  name         = var.domain_name
  private_zone = false
}