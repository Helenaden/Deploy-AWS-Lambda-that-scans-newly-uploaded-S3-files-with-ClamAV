variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
}
variable "s3_bucket_uploads" {
  description = "The S3 bucket name for uploads"
  type        = string
}

variable "s3_bucket_clean" {
  description = "The S3 bucket name for clean files"
  type        = string
}

variable "s3_bucket_quarantine" {
  description = "The S3 bucket name for quarantined files"
  type        = string
}

variable "s3_bucket_clamav" {
  description = "The S3 bucket name for ClamAV files"
  type        = string
}

variable "s3_bucket_web" {
  description = "The S3 bucket name for web index files"
  type        = string
}
variable "notification_email" {
  description = "The email address to receive SNS notifications."
  type        = string
  sensitive   = true 
}