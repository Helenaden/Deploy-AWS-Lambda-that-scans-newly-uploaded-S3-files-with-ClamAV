# Define the KMS key for S3 encryption
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for encrypting files in S3 buckets"
  deletion_window_in_days = 7
}

# Define the KMS key policy
resource "aws_kms_key_policy" "secrets_key_policy" {
  key_id = aws_kms_key.secrets_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Grant the account admin full KMS access
        Effect    = "Allow"
        Principal = { "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        # Grant the S3 service permission to use the key for encryption
        Effect    = "Allow"
        Principal = { "Service" : "s3.amazonaws.com" }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        Resource = "*"
      },
      {
        # Grant our Lambda role permission to decrypt files
        Effect    = "Allow"
        Principal = { "AWS" : aws_iam_role.clamav_scanner_role.arn }
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      },
    ]
  })
}

# Data source to get the current account ID
data "aws_caller_identity" "current" {}