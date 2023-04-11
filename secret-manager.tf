resource "aws_secretsmanager_secret" "ftps_user_habid" {
  name = "aws/transfer/${aws_transfer_server.kantar_watermarking.id}/${var.username}"
}

resource "aws_secretsmanager_secret_version" "ftps_user_username" {
  secret_id = aws_secretsmanager_secret.ftps_user_habid.id
  secret_string = jsonencode({
    Password      = "toto"
    Role          = aws_iam_role.user_role.arn
    HomeDirectory = "/${module.source_bucket.id}"
  })
}