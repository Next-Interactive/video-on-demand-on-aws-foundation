locals {
  endpoint = terraform.workspace == "production" ? "${var.application}.${var.domain_name}" : "${var.application}-${var.environment}.${var.domain_name}"
  raw_video_folder = "raw-videos"
  application = "kantar-watermarking"
}