resource "aws_acm_certificate" "ftps_server" {
  domain_name       = local.endpoint
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ftps_server" {
  provider = aws.root
  for_each = {
    for dvo in aws_acm_certificate.ftps_server.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "ftps_server" {
  certificate_arn         = aws_acm_certificate.ftps_server.arn
  validation_record_fqdns = [for record in aws_route53_record.ftps_server : record.fqdn]
}
