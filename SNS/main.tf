
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

  }
}

provider "aws" {
  profile = "default"
  region  = var.REGION
}
resource "aws_sns_topic" "car_" {
  content_based_deduplication = false
  display_name                = "Car Detected"
  fifo_topic                  = false
  name                        = "car-detect"

}


resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.car_.arn
  protocol  = "email"
  endpoint  = var.EP_EMAIL_ID
}
