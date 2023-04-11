data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "kantar_flow" {
  name = "kantar-flow"
}

resource "aws_sns_topic_subscription" "kantar_flow" {
  topic_arn = aws_sns_topic.kantar_flow.arn
  protocol  = "email"
  endpoint  = var.email_to_notify
}


resource "aws_sns_topic_policy" "kantar_flow" {
  arn = aws_sns_topic.kantar_flow.arn

  policy = data.aws_iam_policy_document.kantar_flow.json
}

data "aws_iam_policy_document" "kantar_flow" {
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.kantar_flow.arn,
    ]
  }
}
