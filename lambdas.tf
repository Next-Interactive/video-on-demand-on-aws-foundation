data "archive_file" "submit_job" {
  type        = "zip"
  source_dir  = "./lambdas/job-submit"
  output_path = "./lambdas-output/job-submit.zip"
}
resource "aws_lambda_function" "submit_job" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = data.archive_file.submit_job.output_path
  function_name    = "${local.application}-submit-job"
  role             = aws_iam_role.lambda_submit_job.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256(data.archive_file.submit_job.output_path)
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
      MEDIACONVERT_ROLE  = aws_iam_role.mediaconvert.arn
      JOB_SETTINGS       = "job-settings.json"
      DESTINATION_BUCKET = module.source_bucket.id
      KANTAR_LOGS_BUCKET = module.kantar_bucket.id
      SOLUTION_ID        = "SO0146"
      SNS_TOPIC_ARN      = aws_sns_topic.kantar_flow.arn
      RAW_VIDEO_FOLDER   = local.raw_video_folder,
      MARKED_VIDEO_FOLDER  = "kantar-watermarked-videos"
      KANTAR_LOG_FOLDER    = "kantar-logs"
    }
  }
}

data "archive_file" "complete_job" {
  type        = "zip"
  source_dir  = "./lambdas/job-complete"
  output_path = "./lambdas-output/job-complete.zip"
}

resource "aws_lambda_function" "complete_job" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = data.archive_file.complete_job.output_path
  function_name    = "${local.application}-complete-job"
  role             = aws_iam_role.lambda_complete_job.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256(data.archive_file.complete_job.output_path)
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
      SOURCE_BUCKET = module.source_bucket.id
      JOB_MANIFEST  = "jobs-manifest.json"
      EMAIL_SENDER  = "exploitation-tech-digital@nextinteractive.fr"
      EMAILS_RECEIVERS = "exploitation-tech-digital@nextinteractive.fr;lise.carriere@alticemedia.com"
      EMAILS_CC        = "hicham.abid.prestataire@alticemedia.com"
    }
  }
}

data "archive_file" "ftps_authentication" {
  type        = "zip"
  source_file = "./lambdas/sftp_authenticator.py"
  output_path = "./lambdas-output/sftp_authentication.zip"
}

resource "aws_lambda_function" "ftps_authentication" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = data.archive_file.ftps_authentication.output_path
  function_name    = "${local.application}-ftps-authentication"
  role             = aws_iam_role.lambda_authentication.arn
  handler          = "sftp_authenticator.lambda_handler"
  runtime          = "python3.7"
  source_code_hash = filebase64sha256(data.archive_file.ftps_authentication.output_path)
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
      SecretsManagerRegion = local.region
    }
  }
}


resource "aws_lambda_permission" "authentication" {
  statement_id  = "AllowExecutionFromApiGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ftps_authentication.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${local.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.ftps_authentication.id}/*"
}


resource "aws_lambda_function" "mediametrie_sftp" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = "sftp_mediametrie_forward.zip"
  function_name    = "${local.application}-mediametrie-log-forward"
  role             = aws_iam_role.lambda_sftp_forward.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("sftp_mediametrie_forward.zip")
  memory_size      = 128
  timeout          = 60
  environment {
    variables = {
      BUCKET = module.kantar_bucket.id
      KANTAR_LOGS_PREFIX = "kantar-logs"
      SFTP_SERVER  = "gw.mediametrie.fr"
      SFTP_USERNAME       = "alticepub-spotreplay"
    }
  }
}

resource "aws_ssm_parameter" "mediametrie_sftp_password" {
  name  = "mediametrie_sftp_password"
  type  = "SecureString"
  value = "changeme"
  lifecycle {
    ignore_changes = [value]
  }
}