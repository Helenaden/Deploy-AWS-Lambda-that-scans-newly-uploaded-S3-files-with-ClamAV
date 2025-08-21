

# Create an IAM role that the Lambda function will assume.
resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-presigner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM role that grants permissions for S3.
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "lambda-s3-access-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Effect = "Allow",
        Resource = "arn:aws:s3:::${var.s3_bucket_uploads}/*"
      },
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        Effect = "Allow",
        Resource = "arn:aws:kms:*:*:key/*"
      },
      {
        Action = "logs:CreateLogGroup",
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
      }
    ]
  })
}

# Package the Python code into a .zip file.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_package.zip"
}

# Create the Lambda function itself.
resource "aws_lambda_function" "s3_presigner_function" {
  function_name    = "S3PresignerFunction"
  handler          = "lambda.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Pass the bucket name as an environment variable to the function.
  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_uploads
    }
  }
}

