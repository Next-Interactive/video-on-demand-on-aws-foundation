resource "aws_api_gateway_rest_api" "ftps_authentication" {
  name = "ftps-authentication"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_account" "ftps_authentication" {
  cloudwatch_role_arn = aws_iam_role.api_gw.arn
}

resource "aws_api_gateway_stage" "ftps_authentication" {
  deployment_id = aws_api_gateway_deployment.ftps_authentication.id
  rest_api_id   = aws_api_gateway_rest_api.ftps_authentication.id
  stage_name    = "production"
}

resource "aws_api_gateway_method_settings" "ftps_authentication" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  stage_name  = aws_api_gateway_stage.ftps_authentication.stage_name
  method_path = "*/*"


  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = false
  }
}

resource "aws_api_gateway_deployment" "ftps_authentication" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
}

resource "aws_api_gateway_resource" "server" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  parent_id   = aws_api_gateway_rest_api.ftps_authentication.root_resource_id
  path_part   = "servers"
}

resource "aws_api_gateway_resource" "server_id" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  parent_id   = aws_api_gateway_resource.server.id
  path_part   = "{serverId}"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  parent_id   = aws_api_gateway_resource.server_id.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "username" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{username}"
}

resource "aws_api_gateway_resource" "config" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  parent_id   = aws_api_gateway_resource.username.id
  path_part   = "config"
}

resource "aws_api_gateway_method" "get_user_config" {
  rest_api_id   = aws_api_gateway_rest_api.ftps_authentication.id
  resource_id   = aws_api_gateway_resource.config.id
  http_method   = "GET"
  authorization = "AWS_IAM"
  request_parameters = {
    "method.request.header.Password" = false
  }
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ftps_authentication.id
  resource_id             = aws_api_gateway_resource.config.id
  http_method             = aws_api_gateway_method.get_user_config.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/${aws_lambda_function.ftps_authentication.arn}/invocations"
  request_templates = {
    "application/json" = <<-EOF
    {
              "username": "$util.urlDecode($input.params('username'))",
              "password": "$util.escapeJavaScript($input.params('Password')).replaceAll("\\'","'")",
              "protocol": "$input.params('protocol')",
              "serverId": "$input.params('serverId')",
              "sourceIp": "$input.params('sourceIp')"
    }
    EOF
  }
}

resource "aws_api_gateway_integration_response" "config" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  resource_id = aws_api_gateway_resource.config.id
  http_method = aws_api_gateway_method.get_user_config.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.ftps_authentication.id
  resource_id = aws_api_gateway_resource.config.id
  http_method = aws_api_gateway_method.get_user_config.http_method
  status_code = "200"
  response_models = {
    "application/json" = "userconfig"
  }
}

resource "aws_api_gateway_model" "config" {
  rest_api_id  = aws_api_gateway_rest_api.ftps_authentication.id
  name         = "userconfig"
  content_type = "application/json"

  schema = jsonencode({
    type      = "object"
    title     = "UserConfigModel"
    "$schema" = "http://json-schema.org/draft-04/schema#"
    properties = {
      HomeDirectory = {
        type = "string"
      }
      Role = {
        type = "string"
      }
      Policy = {
        type = "string"
      }
      PublicKeys = {
        type = "string"
        items = {
          type = "string"
        }
      }
    }
  })
}