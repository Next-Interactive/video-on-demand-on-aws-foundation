resource "aws_route53_record" "static_all_domain_names" {
  provider = aws.root
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = local.endpoint
  type     = "CNAME"
  records  = [aws_transfer_server.kantar_watermarking.endpoint]
  ttl      = 60
}
