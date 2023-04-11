data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_eip" "public_ip" {
  for_each = data.aws_subnet_ids.public.ids

  vpc = true
}

resource "aws_transfer_server" "kantar_watermarking" {
  endpoint_type = "VPC"

  endpoint_details {
    subnet_ids             = tolist(data.aws_subnet_ids.public.ids)
    vpc_id                 = var.vpc_id
    address_allocation_ids = [for eip in aws_eip.public_ip : eip.id]
  }

  protocols              = ["FTPS"]
  certificate            = aws_acm_certificate.ftps_server.arn
  domain                 = "S3"
  identity_provider_type = "API_GATEWAY"
  url                    = aws_api_gateway_stage.ftps_authentication.invoke_url
  invocation_role        = aws_iam_role.transfer_server.arn
}
