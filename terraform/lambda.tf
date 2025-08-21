# Define the ECR repository for the main Lambda scanner
resource "aws_ecr_repository" "clamav_scanner_repo" {
  name                 = "lambda-clamav-scanner"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
# IAM Role for the ClamAV Lambda function.
# This role is assumed by the Lambda service.
resource "aws_iam_role" "clamav_scanner_role" {
  name = "lambda-clamav-scanner-role"

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
}

resource "aws_iam_role_policy" "clamav_scanner_policy" {
  name = "lambda-clamav-scanner-policy"
  role = aws_iam_role.clamav_scanner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:CopyObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.uploads.arn}/*",
          "${aws_s3_bucket.clean.arn}/*",
          "${aws_s3_bucket.quarantine.arn}/*",
          "${aws_s3_bucket.clamav.arn}/*",
        ]
      },
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.uploads.arn,
          aws_s3_bucket.clean.arn,
          aws_s3_bucket.quarantine.arn,
          aws_s3_bucket.clamav.arn,
        ]
      },
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = "arn:aws:kms:*:*:key/*"
      },
      {
        # Add permission for the Lambda function to publish to SNS
        Action = "sns:Publish"
        Effect = "Allow"
        Resource = [
          aws_sns_topic.clean_scan_topic.arn,
          aws_sns_topic.infected_scan_topic.arn,
        ]
      },
    ]
  })
}

# Define the Lambda function
resource "aws_lambda_function" "clamav_scanner" {
  function_name = "ClamAVFileScanner"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.clamav_scanner_repo.repository_url}:latest"
  role          = aws_iam_role.clamav_scanner_role.arn
  timeout       = 300
  memory_size   = 2048

  # Pass the bucket names to the Lambda function via environment variables
  environment {
    variables = {
      QUARANTINE_BUCKET = aws_s3_bucket.quarantine.id
      CLEAN_BUCKET      = aws_s3_bucket.clean.id
      DEFS_BUCKET       = aws_s3_bucket.clamav.id
      DEFS_PREFIX       = "clamav/"
      CLEAN_TOPIC_ARN   = aws_sns_topic.clean_scan_topic.arn
      INFECTED_TOPIC_ARN = aws_sns_topic.infected_scan_topic.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.clamav_scanner_policy,
  ]
}

# Give S3 permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clamav_scanner.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

# Configure the S3 bucket to send notifications to the Lambda function
resource "aws_s3_bucket_notification" "uploads_lambda_trigger" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.clamav_scanner.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_s3_trigger,
  ]
}