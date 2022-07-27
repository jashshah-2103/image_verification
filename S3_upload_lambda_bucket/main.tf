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
resource "aws_s3_bucket" "img" {

  bucket              = "imgveri"
  object_lock_enabled = false
  request_payer       = "BucketOwner"

  grant {
    id = var.CANONICAL_ID
    permissions = [
      "FULL_CONTROL",
    ]
    type = "CanonicalUser"
  }

  versioning {
    enabled    = false
    mfa_delete = false
  }
}

resource "aws_lambda_function" "s3_upload" {
  architectures = [
    "x86_64",
  ]
  filename      = "lambda_function_payload.zip"
  function_name = "s3-upload-event"
  role          = aws_iam_role.img_ver_role.arn
  handler       = "lambda_function.lambda_handler"

  package_type = "Zip"

  runtime          = "python3.9"
  source_code_hash = filebase64sha256("./lambda_function_payload.zip")

  timeout = 60
  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
}


resource "aws_iam_role" "img_ver_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  managed_policy_arns = [
    "arn:aws:iam::${var.ACC_ID}:policy/service-role/AWSLambdaBasicExecutionRole-92571ed4-d32d-4623-becf-d0efd3b14262",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonRekognitionFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
  max_session_duration = 3600
  name                 = "lambda-s3-imgverify"
  path                 = "/service-role/"

}
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_upload.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.img.arn
}


resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.img.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_upload.arn
    events              = ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post"]

  }
  depends_on = [aws_lambda_permission.allow_bucket]
}
