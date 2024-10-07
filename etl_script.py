import sys
from awsglue.context import GlueContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Initialize Glue Context
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session

# Get input arguments for S3 locations
args = getResolvedOptions(sys.argv, ['S3_BUCKET', 'SOURCE_USERS_KEY', 'SOURCE_CALORIES_KEY', 'DESTINATION_KEY'])
bucket = args['S3_BUCKET']
users_path = f"s3://{bucket}/{args['SOURCE_USERS_KEY']}"
calories_path = f"s3://{bucket}/{args['SOURCE_CALORIES_KEY']}"
destination_path = f"s3://{bucket}/{args['DESTINATION_KEY']}"

# Extract data from S3
users_df = spark.read.option("header", "true").csv(users_path)
calories_df = spark.read.option("header", "true").csv(calories_path)

# Join data on user_id
joined_df = users_df.join(calories_df, "user_id")

# Transform Data
transformed_df = joined_df.dropna().withColumn("calories_burned", col("calories_burned").cast("int"))

# Load Transformed Data back to S3
transformed_df.write.mode("overwrite").parquet(destination_path)

print("ETL job completed successfully.")
