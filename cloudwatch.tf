resource "aws_cloudwatch_event_rule" "job_complete" {
  name                = "kantar-job-complete"
  description         = ""
  event_pattern       = <<-EOF
{
    "source": ["aws.mediaconvert"],
    "detail": {
        "userMetadata": {
            "StackName": [
                cdk.Aws.STACK_NAME
            ]
        },
        "status": [
            "COMPLETE",
            "ERROR",
            "CANCELED",
            "INPUT_INFORMATION"
        ]
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "job_complete" {
  rule = aws_cloudwatch_event_rule.job_complete.name
  arn  = aws_lambda_function.job_complete.arn
}

resource "aws_lambda_permission" "job_complete" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.job_complete.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.job_complete.arn
}