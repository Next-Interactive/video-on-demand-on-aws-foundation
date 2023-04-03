module "source_bucket" {
  source = "./s3-module"
  bucket_name = "kantar-watermarking-source"
  environment = "default"
}

resource "aws_s3_bucket_notification" "source" {
  bucket = module.source_bucket.id
  lambda_function {
    lambda_function_arn = ""
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }
}

module "destination_bucket" {
  source = "./s3-module"
  bucket_name = "cf-logs-watermarked-videos"
  environment = "default"
}

module "kantar_bucket" {
  source = "./s3-module"
  bucket_name = "kantar-logs"
  environment = "default"
}

data "template_file" "job_definition" {
  template = file("${path.module}/job-settings.json.tmpl")
}

resource "aws_s3_object" "job_definition" {
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
  bucket  = module.source_bucket.id
  key     = "job-settings.json"
  content = data.template_file.job_definition.rendered
}