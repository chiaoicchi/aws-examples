# ----------
# Lambda Assume Role
# ----------
data "aws_iam_policy_document" "lambda_assume_policy" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_assume_role" { 
  name = "${var.name}-lambda-assume-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" { 
  role = aws_iam_role.lambda_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------
# Lambda 関数の定義
# ----------
data "archive_file" "hello_world_lambda_zip" { 
  type = "zip"
  source_dir = "${path.module}/initial_code"
  output_path = "${path.module}/lambda_zip"
}

resource "aws_lambda_function" "hello_world_lambda" { 
  filename = data.archive_file.hello_world_lambda_zip.output_path
  function_name = "${var.name}-hello-world"
  role = aws_iam_role.lambda_assume_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"
  source_code_hash = data.archive_file.hello_world_lambda_zip.output_base64sha256
}
