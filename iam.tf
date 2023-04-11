resource "aws_iam_role" "mediaconvert" {
  name               = "mediaconvert-${local.application}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "mediaconvert.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "mediaconvert" {
  name   = "mediaconvert-${local.application}"
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
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }
  ]
}
EOF

  role = aws_iam_role.mediaconvert.id
}


resource "aws_iam_role" "lambda_submit_job" {
  name = "lambda-${local.application}-submit-job"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_submit_job" {
  name = "lambda-${local.application}-submit-job"
  role = aws_iam_role.lambda_submit_job.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.mediaconvert.arn}"
    },
    {
      "Effect":"Allow",
      "Action": "mediaconvert:*",
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": "s3:GetObject",
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": "SNS:Publish",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_complete_job" {
  name = "lambda-${local.application}-complete-job"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_complete_job" {
  name = "lambda-complete-job"
  role = aws_iam_role.lambda_complete_job.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": "mediaconvert:*",
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": "SNS:Publish",
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": ["ses:SendEmail","ses:sendRawEmail"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_complete_job" {
  role       = aws_iam_role.lambda_complete_job.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_submit_job" {
  role       = aws_iam_role.lambda_submit_job.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_authentication" {
  name = "lambda-${local.application}-authentication"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_authentication_secrets" {
  name = "lambda-${local.application}-authentication-secrets"
  role = aws_iam_role.lambda_authentication.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "${aws_secretsmanager_secret.ftps_user_habid.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_authentication" {
  role       = aws_iam_role.lambda_authentication.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "api_gw" {
  name = "api-gw-${local.application}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "api_gw" {
  name = "api-gw-cloudwatch"
  role = aws_iam_role.api_gw.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents"
            ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "user_role" {
  name = "ftps-${local.application}-user-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "user_role" {
  name = "ftps-user-role"
  role = aws_iam_role.user_role.id

  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListingOfUserFolder",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${module.source_bucket.id}"
            ]
        },
        {
            "Sid": "HomeDirObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:GetObjectVersion",
                "s3:GetObjectACL",
                "s3:PutObjectACL"
            ],
            "Resource": "arn:aws:s3:::${module.source_bucket.id}/*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "transfer_server" {
  name = "ftps-transfer-server"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transfer_server" {
  role       = aws_iam_role.transfer_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}


resource "aws_iam_role" "lambda_sftp_forward" {
  name = "kantar-log-sftp-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sftp_forward" {
  role       = aws_iam_role.lambda_sftp_forward.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sftp_forward" {
  name = "kantar-log-sftp-lambda-policy"
  role = aws_iam_role.lambda_sftp_forward.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
      "Resource": [
                  "arn:aws:s3:::${module.kantar_bucket.id}/*",
                  "arn:aws:s3:::${module.kantar_bucket.id}"
                  ]
    },
    {
            "Action": [
                "ssm:GetParameter",
                "kms:Decrypt"
            ],
            "Resource": "${aws_ssm_parameter.mediametrie_sftp_password.arn}",
            "Effect": "Allow"
    }
  ]
}
EOF
}