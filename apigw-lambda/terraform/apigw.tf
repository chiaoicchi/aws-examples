resource "aws_iam_role" "apigw_execution_role" {
  name = "${var.prefix}-apigw-execution-role"
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
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "apigw_execution_role_logs" {
  role       = aws_iam_role.apigw_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
resource "aws_iam_role_policy_attachment" "apigw_execution_role_invoke_lambda" {
  role       = aws_iam_role.apigw_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.prefix}-api"
  tags = local.tags
}
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root.id,
      aws_api_gateway_method.get_root.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_integration.get_root]
}
resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.prod.id
  stage_name    = "prod"
}
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "yo"
}
resource "aws_api_gateway_method" "get_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.root.id
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "get_root" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.get_root.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.get_root_function.invoke_arn
}
