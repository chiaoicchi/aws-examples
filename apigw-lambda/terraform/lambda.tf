resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.prefix}-lambda-execution-role"
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
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "lambda_execution_role_lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "get_root_function" {
  type        = "zip"
  source_dir  = "${path.module}/../app/get_root"
  output_path = "${path.module}/lambda/get_root_function.zip"
}
resource "aws_lambda_function" "get_root_function" {
  filename         = data.archive_file.get_root_function.output_path
  function_name    = "${var.prefix}-get-root-function"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = data.archive_file.get_root_function.output_base64sha256
  tags             = local.tags
}
resource "aws_lambda_permission" "get_root_function_from_api_gateway" {
  statement_id  = "AllowExecutionGetRootFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_root_function.function_name
  principal     = "apigateway.amazonaws.com"
}
