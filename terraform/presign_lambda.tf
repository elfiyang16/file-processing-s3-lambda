data "archive_file" "presign_archive" {
  type        = "zip"
  source_file = "${path.module}/../lambdas/presign.py"
  output_path = "${path.module}/../presign_archive.zip"
}

resource "aws_lambda_function" "presign_lambda" {
  function_name    = "${var.name_base}_presign"
  role             = aws_iam_role.presign_lambda_execution_role.arn
  runtime          = "python3.7"
  handler          = "presign.lambda_handler"
  filename         = "./presign_archive.zip"
  source_code_hash = data.archive_file.presign_archive.output_base64sha256
  environment {
    variables = {
      UPLOADER = local.upload_bucket_name
    }
  }
}

resource "aws_cloudwatch_log_group" "presign_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.presign_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_iam_role" "presign_lambda_execution_role" {
  name               = "${var.name_base}_presign_lambda_exec_role_${local.aws_region}"
  path               = "/lambda/"
  assume_role_policy = data.aws_iam_policy_document.presign_exec_role_lambda_trust_policy.json
  inline_policy {
    # Change to match CloudFormation.
    name = "anameisrequired"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:PutObject*",
          ]
          Effect   = "Allow"
          Resource = ["${aws_s3_bucket.upload_bucket.arn}/*"]
        },
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "presign_basic_lambda" {
  role       = aws_iam_role.presign_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "presign_exec_role_lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_permission" "api_presign_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*/*"
}
