module "source_bucket" {
  source      = "./s3-module"
  bucket_name = "kantar-watermarking-source"
  environment = "default"
}

resource "aws_s3_bucket_notification" "source" {
  bucket = module.source_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.submit_job.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.raw_video_folder}/"
  }
}

resource "aws_lambda_permission" "job_submit" {
  statement_id  = "AllowExecutionFroms3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit_job.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${module.source_bucket.id}"
}

module "destination_bucket" {
  source      = "./s3-module"
  bucket_name = "kantar-watermarking-destination"
  environment = "default"
}

module "kantar_bucket" {
  source      = "./s3-module"
  bucket_name = "kantar-logs"
  environment = "default"
}

resource "aws_s3_object" "job_definition" {
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
  bucket  = module.source_bucket.id
  key     = "${local.raw_video_folder}/job-settings.json"
  content = templatefile("${path.module}/job-settings.json.tmpl", {})
}

resource "aws_s3_object" "jobs_manifest" {
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
  bucket  = module.source_bucket.id
  key     = "jobs-manifest.json"
  content = templatefile("${path.module}/jobs-manifest.json.tmpl", {})
}
