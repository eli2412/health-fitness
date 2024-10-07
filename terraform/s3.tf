resource "aws_s3_bucket" "s3_multiverse" {
  bucket = "s3-multiverse"
}

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
