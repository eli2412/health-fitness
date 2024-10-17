# S3 bucket
resource "aws_s3_bucket" "s3_multiverse" {
  bucket = "s3-multiverse"
}

#objects 
resource "aws_s3_bucket_object" "users_file" {
  bucket = aws_s3_bucket.s3_multiverse.bucket
  key    = "data/users.csv"
  source = "../users.csv"
}

resource "aws_s3_bucket_object" "calories_burned_file" {
  bucket = aws_s3_bucket.s3_multiverse.bucket
  key    = "data/calories_burned.csv"
  source = "../calories_burned.csv"
}

resource "aws_s3_bucket_object" "etl_script" {
  bucket = aws_s3_bucket.s3_multiverse.bucket
  key    = "scripts/etl_script.py"
  source = "../etl_script.py"
}

resource "aws_s3_bucket_object" "lambda_script" {
  bucket = aws_s3_bucket.s3_multiverse.bucket
  key    = "lambda/s3_event_processor.zip"
  source = "../s3_event_processor.zip"
}

#lambda function
resource "aws_lambda_function" "s3_file_processing" {
  function_name = "S3FileProcessing"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  depends_on = [ aws_s3_bucket_object.lambda_script ]

  s3_bucket = aws_s3_bucket.s3_multiverse.bucket
  s3_key    = "lambda/s3_event_processor.zip"
  
  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.etl_job.name
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_s3_bucket_notification" "s3_upload_notification" {
  bucket = aws_s3_bucket.s3_multiverse.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_file_processing.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}

resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_file_processing.function_name
  principal     = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.s3_multiverse.arn
}


