provider "aws" {
  region = var.region
}


resource "aws_s3_bucket" "bucket" {
  count = var.bucket_name != "" ? 1 : 0  # Only create if bucket_name is set
  bucket = var.bucket_name

  versioning {
    enabled = true
  }
}



resource "aws_s3_object" "source_folder" {
  count = var.bucket_name != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket[count.index].id
  key    = var.source_folder
  content_type = "application/x-directory"
}

resource "aws_s3_object" "target_folder" {
  count = var.bucket_name != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket[count.index].id
  key    = var.target_folder
  content_type = "application/x-directory"
}

resource "aws_s3_object" "inbound_folder" {
  count = var.bucket_name != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket[count.index].id
  key    = var.inbound_folder
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_object" "file_upload" {
  count = var.bucket_name != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket[count.index].id
  key    = "src/lambda-function.zip"
  source = "${path.module}/lambda-function.zip"
}


module "lambda_role" {
  source = "./modules/lambda_role"

  # Set any additional inputs for the module here, such as a custom role name.
}

resource "aws_lambda_function" "python_lambda" {
  function_name    = "my_lambda_function"
  role             =  module.lambda_role.arn
  handler          = "readEventWrite.lambda_handler"
  runtime          = "python3.8"
  s3_bucket        = "shuvabuc007"
  s3_key           = "src/lambda-function.zip"
  depends_on = [aws_s3_bucket_object.file_upload]
}

resource "aws_lambda_permission" "allow_bucket" {
  count         = length(aws_s3_bucket.bucket)
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket[count.index].arn
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_lambda_function.python_lambda]

  create_duration = "30s"
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  
  count  = length(aws_s3_bucket.bucket) # This line ensures the same count as the aws_s3_bucket resource
  bucket = aws_s3_bucket.bucket[count.index].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.python_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "inbound/" # Add this line to specify the prefix
  }

  depends_on = [
    aws_lambda_function.python_lambda,
    time_sleep.wait_30_seconds
  ]
}
