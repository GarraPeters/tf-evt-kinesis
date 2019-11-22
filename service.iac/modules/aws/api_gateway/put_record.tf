resource "aws_api_gateway_resource" "record" {
  for_each    = { for k, v in var.service_apps : k => v }
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  parent_id   = aws_api_gateway_resource.stream[each.key].id
  path_part   = "record"
}

resource "aws_api_gateway_method" "put_record" {
  for_each      = { for k, v in var.service_apps : k => v }
  rest_api_id   = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id   = aws_api_gateway_resource.record[each.key].id
  http_method   = "PUT"
  authorization = "NONE"
  //   api_key_required = true
}

resource "aws_api_gateway_integration" "put_record" {
  for_each                = { for k, v in var.service_apps : k => v }
  rest_api_id             = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id             = aws_api_gateway_resource.record[each.key].id
  http_method             = aws_api_gateway_method.put_record[each.key].http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:kinesis:action/PutRecord"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  credentials             = aws_iam_role.gateway_execution_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }

  # Passthrough the JSON response
  request_templates = {
    "application/json" = <<EOF
{
    "StreamName": "$input.params('stream-name')",
    "Data": "$util.base64Encode($input.json('$.data'))",
    "PartitionKey": $input.json('$.partition-key')
}
EOF
  }
}

resource "aws_api_gateway_method_response" "put_record_ok" {
  for_each    = { for k, v in var.service_apps : k => v }
  depends_on  = ["aws_api_gateway_method.put_record"]
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id = aws_api_gateway_resource.record[each.key].id
  http_method = aws_api_gateway_method.put_record[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "put_record" {
  for_each    = { for k, v in var.service_apps : k => v }
  rest_api_id = aws_api_gateway_rest_api.kinesis_proxy[each.key].id
  resource_id = aws_api_gateway_resource.record[each.key].id
  http_method = aws_api_gateway_method.put_record[each.key].http_method
  status_code = aws_api_gateway_method_response.put_record_ok[each.key].status_code

  # Passthrough the JSON response
  response_templates = {
    "application/json" = <<EOF
EOF
  }
}
