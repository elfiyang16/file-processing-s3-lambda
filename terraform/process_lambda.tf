
data "archive_file" "process_archive" {
  type        = "zip"
  source_file = "${path.module}/../lambdas/process.py"
  output_path = "${path.module}/../process_archive.zip"
}

resource "aws_lambda_function" "process_lambda" {
  function_name    = "${var.name_base}_process"
  role             = aws_iam_role.process_lambda_execution_role.arn
  runtime          = "python3.7"
  handler          = "process.lambda_handler"
  filename         = "./process_archive.zip"
  source_code_hash = data.archive_file.process_archive.output_base64sha256
  environment {
    variables = {
      # Requires only the archive bucket name.  The upload
      # bucket name gets passed to it when triggered.
      ARCHIVER = local.archive_bucket_name
    }
  }
}

resource "aws_cloudwatch_log_group" "process_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.process_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "upload_bucket_lambda_invocation" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}

resource "aws_s3_bucket_notification" "upload_bucket_notification" {
  bucket = aws_s3_bucket.upload_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.process_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.upload_bucket_lambda_invocation]
}

resource "aws_iam_role" "process_lambda_execution_role" {
  name               = "${var.name_base}_process_lambda_exec_role_${local.aws_region}"
  path               = "/lambda/"
  assume_role_policy = data.aws_iam_policy_document.process_exec_role_lambda_trust_policy.json
  inline_policy {
    # Change to match CloudFormation.
    name = "anameisrequired"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:DeleteObject",
          ]
          Effect   = "Allow"
          Resource = ["${aws_s3_bucket.upload_bucket.arn}/*"]
        },
        {
          Action = [
            "s3:PutObject",
          ]
          Effect   = "Allow"
          Resource = ["${aws_s3_bucket.archive_bucket.arn}/*"]
        },
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "process_lambda_write" {
  role       = aws_iam_role.process_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "process_basic_lambda" {
  role       = aws_iam_role.process_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "process_exec_role_lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "process_read_from_upload_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.upload_bucket.arn}/*"]
      },
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.archive_bucket.arn}/*"]
      },
    ]
  })
}

