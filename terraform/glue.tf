#databases
resource "aws_glue_catalog_database" "users_glue_dbs" {
  name = "users-database"
}

resource "aws_glue_catalog_database" "calories_burned_glue_dbs" {
  name = "calories-burned-database"
}

#tables
resource "aws_glue_catalog_table" "users_table" {
  name          = "users"
  database_name = aws_glue_catalog_database.users_glue_dbs.name

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.s3_multiverse.bucket}/data/users.csv"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = false

    columns {
      name = "user_id"
      type = "int"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "age"
      type = "int"
    }
    columns {
      name = "gender"
      type = "string"
    }
    ser_de_info {
      name                  = "OpenCSVSerDe"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
    }
  }

  table_type = "EXTERNAL_TABLE"
}

resource "aws_glue_catalog_table" "calories_burned_table" {
  name          = "calories-burned-table"
  database_name = aws_glue_catalog_database.calories_burned_glue_dbs.name

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.s3_multiverse.bucket}/data/calories_burned.csv"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = false

    columns {
      name = "workout_id"
      type = "int"
    }
    columns {
      name = "user_id"
      type = "int"
    }
    columns {
      name = "date"
      type = "string"
    }
    columns {
      name = "calories_burned"
      type = "int"
    }
    ser_de_info {
      name                  = "OpenCSVSerDe"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
    }
  }

  table_type = "EXTERNAL_TABLE"
}

# Crawler
resource "aws_glue_crawler" "users_crawler" {
  database_name = aws_glue_catalog_database.users_glue_dbs.name
  name          = "users-crawlers"
  role          = aws_iam_role.glue_admin_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.s3_multiverse.bucket}"
  }
}

resource "aws_glue_crawler" "calories_burned_crawler" {
  database_name = aws_glue_catalog_database.calories_burned_glue_dbs.name
  name          = "calories-burned-crawlers"
  role          = aws_iam_role.glue_admin_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.s3_multiverse.bucket}"
  }
}

resource "aws_iam_role" "glue_admin_role" {
  name = "glue_admin_role"

  # Glue use case: Allow AWS Glue to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AdministratorAccess policy
resource "aws_iam_role_policy_attachment" "glue_admin_role_admin_policy" {
  role       = aws_iam_role.glue_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Attach AWS Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_admin_role_glue_policy" {
  role       = aws_iam_role.glue_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}



#Glue job
resource "aws_glue_job" "etl_job" {
  name     = "fitness-health-etl"
  role_arn = aws_iam_role.glue_admin_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://s3-multiverse/scripts/etl_script.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-bookmark-option"  = "job-bookmark-enable"
    "--enable-metrics"       = "true"
    "--S3_BUCKET"            = aws_s3_bucket.s3_multiverse.bucket
    "--SOURCE_USERS_KEY"     = "data/users.csv"
    "--SOURCE_CALORIES_KEY"  = "data/calories_burned.csv"
    "--DESTINATION_KEY"      = "data/transformed/"
  }

  max_retries  = 1
  timeout      = 20
  glue_version = "3.0"
}

#glue trigger
resource "aws_glue_trigger" "health_fitness_trigger" {
  name = "health-job"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_job.etl_job.name
  }
}