# Core, Bucket & Table
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.6"
}

provider "aws" {
  profile = "answer-digital"
  region = "eu-west-2"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "js-input-bucket-tech-talk-tf"
  acl = "private"
}

resource "aws_dynamodb_table" "table" {
  name = "js-weather-tf"
  hash_key = "location"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "location"
    type = "S"
  }
}

# Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas"
  output_path = "${path.module}/lambda_code.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "js-weather-tf"
  handler = "main.lambda_handler"
  role = aws_iam_role.role.arn
  runtime = "python3.8"
  timeout = "15"
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      WEATHER_API_KEY = "INSERT_API_KEY_HERE"
    }
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "${path.module}/lambda_layer.zip"
  layer_name          = "lambda_layer"
  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_function_event_invoke_config" "lambda_config" {
  function_name                = aws_lambda_function.lambda.function_name
  maximum_retry_attempts       = 0
}

# IAM Role
resource "aws_iam_role" "role" {
  name               = "lambda-iam-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
 EOF
}

resource "aws_iam_policy" "policy" {
  name        = "lambda-iam-policy"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": "dynamodb:BatchWriteItem",
            "Resource": [
                "${aws_dynamodb_table.table.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource":"${aws_s3_bucket.bucket.arn}/*"
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# Additional permissions and notifiers
resource "aws_lambda_permission" "lambda_allow_bucket_to_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}