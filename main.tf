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

module "preassigned_url" {
  source = "./preassigned_url_lambda"
}

module "S3_upload_lambda_bucket" {
  source = "./S3_upload_lambda_bucket"
}
module "sns" {
  source = "./SNS"
}