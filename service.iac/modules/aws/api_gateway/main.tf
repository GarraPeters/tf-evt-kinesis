resource "aws_iam_role" "gateway_execution_role" {
  name = "evt-gateway-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "gateway_execution_role_policy" {
  template = file("${path.module}/policies/AmazonKinesisFullAccess-policy.json")
}

resource "aws_iam_role_policy" "scheduled_task_ecs_execution" {

  name   = "evt-gateway-execution-role-policy"
  role   = aws_iam_role.gateway_execution_role.id
  policy = data.template_file.gateway_execution_role_policy.rendered
}



data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "kinesis_proxy" {
  // for_each = { for k, v in var.service_apps : k => v }
  name = "evt-kinesis_proxy"

}

resource "aws_api_gateway_resource" "streams" {

  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy.id
  parent_id   = aws_api_gateway_rest_api.kinesis_proxy.root_resource_id
  path_part   = "streams"
}

resource "aws_api_gateway_method" "list_streams" {

  rest_api_id   = aws_api_gateway_rest_api.kinesis_proxy.id
  resource_id   = aws_api_gateway_resource.streams.id
  http_method   = "GET"
  authorization = "NONE"
  // api_key_required = true
}

resource "aws_api_gateway_integration" "list_streams" {

  rest_api_id             = aws_api_gateway_rest_api.kinesis_proxy.id
  resource_id             = aws_api_gateway_resource.streams.id
  http_method             = aws_api_gateway_method.list_streams.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:kinesis:action/ListStreams"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  credentials             = aws_iam_role.gateway_execution_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }

  # Passthrough the JSON response
  request_templates = {
    "application/json" = <<EOF
{}
EOF
  }
}

resource "aws_api_gateway_method_response" "list_streams_ok" {

  depends_on  = ["aws_api_gateway_method.list_streams"]
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy.id
  resource_id = aws_api_gateway_resource.streams.id
  http_method = aws_api_gateway_method.list_streams.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "list_streams_ok" {

  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy.id
  resource_id = aws_api_gateway_resource.streams.id
  http_method = aws_api_gateway_method.list_streams.http_method
  status_code = aws_api_gateway_method_response.list_streams_ok.status_code

  # Passthrough the JSON response
  response_templates = {
    "application/json" = <<EOF
  EOF
  }
}
