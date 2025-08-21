terraform {
  backend "s3" {
    bucket         = "mybackendbucket-22"
    key            = "Deploy-AWS-Lambda-that-scans-newly-uploaded-S3-files-with-ClamAV/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}