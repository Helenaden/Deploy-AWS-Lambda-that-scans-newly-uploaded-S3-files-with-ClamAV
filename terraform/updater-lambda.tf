# ECR Repository for the Updater Lambda
resource "aws_ecr_repository" "clamav_updater_repo" {
  name                 = "clamav-updater"
  image_tag_mutability = "MUTABLE"
}
# IAM Role for the Lambda Updater Function
resource "aws_iam_role" "clamav_updater_role" {
  name = "clamav-updater-role"
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

# IAM Policy for the Lambda Updater Function
resource "aws_iam_role_policy" "clamav_updater_policy" {
  name = "clamav-updater-policy"
  role = aws_iam_role.clamav_updater_role.id
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.clamav.arn,
          "${aws_s3_bucket.clamav.arn}/*"
        ]
      },
    ]
  })
}

# The Lambda Function for the Updater
resource "aws_lambda_function" "clamav_updater" {
  function_name = "ClamAVUpdater"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.clamav_updater_repo.repository_url}:latest"
  role          = aws_iam_role.clamav_updater_role.arn
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      CLAMAV_DEFS_BUCKET = aws_s3_bucket.clamav.id
    }
  }
}

# EventBridge Rule to trigger the Lambda on a schedule (e.g., once a day)
resource "aws_cloudwatch_event_rule" "clamav_updater_schedule" {
  name                = "clamav-updater-schedule"
  schedule_expression = "cron(0 12 * * ? *)" # Runs every day at 12:00 PM UTC
}

# EventBridge Target to link the rule to the Lambda function
resource "aws_cloudwatch_event_target" "clamav_updater_target" {
  rule      = aws_cloudwatch_event_rule.clamav_updater_schedule.name
  arn       = aws_lambda_function.clamav_updater.arn
}

# Lambda Permission for EventBridge to invoke the function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clamav_updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.clamav_updater_schedule.arn
}