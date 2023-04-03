resource "aws_iam_role" "mediaconvert" {
  name               = "${local.full_name}-ecs-tasks"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "'mediaconvert.amazonaws.com'"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "mediaconvert" {
  name   = "ecs-autoscaling-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${module.source_bucket.id}/*",
        "arn:aws:s3:::${module.destination_bucket.id}/*",
        "arn:aws:s3:::${module.kantar_bucket.id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${module.kantar_bucket.id}"
    }
  ]
}
EOF

  role = aws_iam_role.mediaconvert.id
}
