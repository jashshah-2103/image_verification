variable "REGION" {
  type = string
  default = "us-east-1"
}
variable "ACC_ID" {
  type = string
  default = "056999812124"
}
variable "CANONICAL_ID" {
  type = string
  default = "6b903ce05b8fd7ce1e718c961bc639496829206bb258c83f79df775c3228e3ad"
}
variable "EP_EMAIL_ID" {
  type=string
  default="jashshah2103@gmail.com"
}
variable "lambda_assume_role_policy_document" {
  type        = string
  description = "assume role policy document"
  default     = <<-EOF
   {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow"
        }
      ]
   }
  EOF
}