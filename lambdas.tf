data "archive_file" "submit_job" {
  type        = "zip"
  source_file = "./lambdas/job_submit.js"
  output_path = "./lambdas/job_submit.zip"
}
resource "aws_lambda_function" "submit_job" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = data.archive_file.submit_job.output_path
  function_name    = "kantar-watermarking-submit-job"
  role             = aws_iam_role.lambda_submit_job.arn
  handler          = "job_submit.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256(data.archive_file.submit_job.output_path)
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
        MEDIACONVERT_ROLE = "arn"
        JOB_SETTINGS ="job-settings.json"
        DESTINATION_BUCKET = module.destination_bucket.id
        KANTAR_LOGS_BUCKET = module.kantar_bucket.id
        SOLUTION_ID = "SO0146"
        SNS_TOPIC_ARN = "arn"
    }
  }
}

data "archive_file" "complete_job" {
  type        = "zip"
  source_file = "./lambdas/job_complete"
  output_path = "./lambdas/job_complete.zip"
}

resource "aws_lambda_function" "complete_job" {
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_115:Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  #checkov:skip=CKV_AWS_50:X-ray tracing is enabled for Lambda
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  filename         = data.archive_file.complete_job.output_path
  function_name    = "kantar-watermarking-complete-job"
  role             = aws_iam_role.lambda_submit_job.arn
  handler          = "job_submit.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256(data.archive_file.complete_job.output_path)
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
        SNS_TOPIC_ARN = "sns"
        SOURCE_BUCKET = module.source_bucket.id
        JOB_MANIFEST  = "jobs-manifest.json"
        METRICS       = "No"
        SOLUTION_ID   = "SO0146"
        VERSION       = "1.1.0"
        UUID          = ""
    }
  }
}