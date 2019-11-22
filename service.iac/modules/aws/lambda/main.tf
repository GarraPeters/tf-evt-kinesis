data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  for_each = { for k, v in var.service_apps : k => v }
  name     = "${each.key}-iam_for_lambda-policy"

  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "kinesis:ListStreams"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListTagsForStream"
            ],
            "Effect": "Allow",
            "Resource": [
              "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.aws_kinesis_stream[each.key].name}"
            ]
        }
        
    ]
}
EOF
}



resource "aws_lambda_function" "lambda" {
  for_each      = { for k, v in var.service_apps : k => v }
  filename      = "${path.module}/lambda_test.zip"
  function_name = "evt-${each.key}-LambdaStreamToFirehose"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "index.handler"
  runtime       = "python2.7"

  environment {
    variables = {
      USE_DEFAULT_DELIVERY_STREAMS = "false"
    }
  }
}

resource "aws_lambda_event_source_mapping" "event" {
  for_each          = { for k, v in var.service_apps : k => v }
  batch_size        = 100
  event_source_arn  = var.aws_kinesis_stream[each.key].arn
  enabled           = true
  function_name     = aws_lambda_function.lambda[each.key].arn
  starting_position = "TRIM_HORIZON"
}
