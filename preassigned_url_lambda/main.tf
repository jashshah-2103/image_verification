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
resource "aws_apigatewayv2_api" "s3upload" {
  name          = "s3upload"
  protocol_type = "HTTP"
}
resource "aws_apigatewayv2_stage" "v1" {
  api_id      = aws_apigatewayv2_api.s3upload.id
  name        = "v1"
  auto_deploy = true
}
resource "aws_apigatewayv2_integration" "s3upload" {
  api_id           = aws_apigatewayv2_api.s3upload.id
  integration_type = "AWS_PROXY"
  connection_type           = "INTERNET"
  description               = "s3upload presign url"
  integration_method        = "POST"
  integration_uri = aws_lambda_function.preassnurl.invoke_arn
}
resource "aws_apigatewayv2_route" "s3upload" {
  api_id    = aws_apigatewayv2_api.s3upload.id
  operation_name = "s3upload"
  route_key      = "GET /url"
  target="integrations/${aws_apigatewayv2_integration.s3upload.id}"
}

resource "aws_lambda_permission" "apigw-permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.preassnurl.function_name
  principal     = "apigateway.amazonaws.com"
  # The /*/*/* part allows invocation from any stage, method and resource path
  source_arn = "${aws_apigatewayv2_api.s3upload.execution_arn}/*/*/*"
}
resource "aws_iam_policy" "my-lambda-iam-policy" {
  name        = "my-lambda-iam-policy"
  path        = "/"
  description = "My lambda policy - base"
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }
  EOF
}
resource "aws_iam_role" "lambda-s3-role" {
  name = "my_lambda_iam_s3_role"
  assume_role_policy = var.lambda_assume_role_policy_document
}
resource "aws_iam_role_policy_attachment" "base-role" {
  role       = aws_iam_role.lambda-s3-role.name
  policy_arn = aws_iam_policy.my-lambda-iam-policy.arn
}
data "aws_iam_policy" "s3-admin-policy"{
  name = "AmazonS3FullAccess" 
}
resource "aws_iam_role_policy_attachment" "s3-role" {
  role       = aws_iam_role.lambda-s3-role.name
  policy_arn = data.aws_iam_policy.s3-admin-policy.arn
}
resource "aws_lambda_function" "preassnurl" {
    
    filename                       = "lambda_function_preassnurl.zip"
    function_name                  = "preassigned_url_gen"
    handler                        = "lambda_function.lambda_handler"
    role                           = aws_iam_role.lambda-s3-role.arn
    runtime                        = "python3.9"
    source_code_hash               = filebase64sha256("lambda_function_preassnurl.zip")
   
    timeout                        = 3
    
}