resource "aws_transfer_server" "kantar_watermarking" {
  endpoint_type = "VPC"

  endpoint_details {
    subnet_ids = [aws_subnet.example.id]
    vpc_id     = aws_vpc.example.id
  }

  protocols   = ["FTPS"]
  certificate = aws_acm_certificate.example.arn
  domain = "S3"
}

resource "aws_transfer_user" "regie" {
  server_id = aws_transfer_server.kantar_watermarking.id
  user_name = "stephanie"
  role      = aws_iam_role.foo.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/test.pdf"
    target = "/bucket3/test-path/tftestuser.pdf"
  }
}