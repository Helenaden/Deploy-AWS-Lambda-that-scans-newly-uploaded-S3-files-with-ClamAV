# SNS Topic for successful scans
resource "aws_sns_topic" "clean_scan_topic" {
  name = "clamav-clean-scan-notifications"
}

# SNS Topic for malware threats
resource "aws_sns_topic" "infected_scan_topic" {
  name = "clamav-infected-scan-notifications"
}

# Subscribe the verified email address to the clean topic
resource "aws_sns_topic_subscription" "clean_scan_subscription" {
  topic_arn = aws_sns_topic.clean_scan_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email 
}

# Subscribe the verified email address to the infected topic
resource "aws_sns_topic_subscription" "infected_scan_subscription" {
  topic_arn = aws_sns_topic.infected_scan_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email 
}