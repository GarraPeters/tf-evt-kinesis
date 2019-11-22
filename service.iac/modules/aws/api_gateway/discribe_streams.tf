resource "aws_api_gateway_resource" "stream" {
  for_each    = { for k, v in var.service_apps : k => v }
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  parent_id   = aws_api_gateway_resource.streams[each.key].id
  path_part   = "{stream-name}"
}

resource "aws_api_gateway_method" "describe_stream" {
  for_each      = { for k, v in var.service_apps : k => v }
  rest_api_id   = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id   = aws_api_gateway_resource.stream[each.key].id
  http_method   = "GET"
  authorization = "NONE"
  //   api_key_required = true
}

resource "aws_api_gateway_integration" "describe_stream" {
  for_each                = { for k, v in var.service_apps : k => v }
  rest_api_id             = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id             = aws_api_gateway_resource.stream[each.key].id
  http_method             = aws_api_gateway_method.describe_stream[each.key].http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:kinesis:action/DescribeStream"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  credentials             = aws_iam_role.gateway_execution_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/json" = <<EOF
{
    "StreamName": "$input.params('stream-name')"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "describe_stream_ok" {
  for_each    = { for k, v in var.service_apps : k => v }
  depends_on  = ["aws_api_gateway_method.describe_stream"]
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id = aws_api_gateway_resource.stream[each.key].id
  http_method = aws_api_gateway_method.describe_stream[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "describe_stream_ok" {
  for_each    = { for k, v in var.service_apps : k => v }
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id = aws_api_gateway_resource.stream[each.key].id
  http_method = aws_api_gateway_method.describe_stream[each.key].http_method
  status_code = aws_api_gateway_method_response.describe_stream_ok[each.key].status_code

  # Passthrough the JSON response
  response_templates = {
    "application/json" = <<EOF
EOF
  }
}
