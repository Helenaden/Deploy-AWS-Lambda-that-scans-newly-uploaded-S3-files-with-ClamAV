
# -------------------- S3 BUCKETS --------------------
# This file defines the S3 bucket for uploads, including versioning and encryption settings.
#upload bucket
resource "aws_s3_bucket" "uploads" {
  bucket = var.s3_bucket_uploads

  tags = {
    Name = "App Files Uploads Bucket"
  }
}

resource "aws_s3_bucket_versioning" "uploads_versioning" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads_encryption" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads_pab" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#clean bucket
resource "aws_s3_bucket" "clean" {
  bucket = var.s3_bucket_clean

  tags = {
    Name = "Clean Files Bucket"
  }
}

resource "aws_s3_bucket_versioning" "clean_versioning" {
  bucket = aws_s3_bucket.clean.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clean_encryption" {
  bucket = aws_s3_bucket.clean.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "clean_pab" {
  bucket = aws_s3_bucket.clean.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Quarantine bucket
resource "aws_s3_bucket" "quarantine" {
  bucket = var.s3_bucket_quarantine

  tags = {
    Name = "Quarantine Files Bucket"
  }
}

resource "aws_s3_bucket_versioning" "quarantine_versioning" {
  bucket = aws_s3_bucket.quarantine.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "quarantine_encryption" {
  bucket = aws_s3_bucket.quarantine.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "quarantine_pab" {
  bucket = aws_s3_bucket.quarantine.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#ClamAV bucket
resource "aws_s3_bucket" "clamav" {
  bucket = var.s3_bucket_clamav

  tags = {
    Name = "ClamAV Files Bucket"
  }
}

resource "aws_s3_bucket_versioning" "clamav_versioning" {
  bucket = aws_s3_bucket.clamav.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clamav_encryption" {
  bucket = aws_s3_bucket.clamav.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "clamav_pab" {
  bucket = aws_s3_bucket.clamav.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}











