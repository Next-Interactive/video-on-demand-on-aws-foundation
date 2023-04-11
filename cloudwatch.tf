resource "aws_cloudwatch_event_rule" "job_complete" {
  name          = "kantar-job-complete"
  description   = ""
  event_pattern = <<-EOF
{
    "source": ["aws.mediaconvert"],
    "detail": {
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
  arn  = aws_lambda_function.complete_job.arn
}

resource "aws_lambda_permission" "job_complete" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.complete_job.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.job_complete.arn
}
