import json
import boto3

def lambda_handler(event, context):
    glue_client = boto3.client('glue')
    s3_client = boto3.client('s3')
    
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        
        print(f"File {object_key} uploaded to {bucket_name}")
        
        if object_key.endswith("users.csv"):
            print("Processing users file...")
            trigger_glue_job(glue_client, bucket_name, 'data/users.csv', 'data/calories_burned.csv')
        elif object_key.endswith("calories_burned.csv"):
            print("Processing calories burned file...")
            trigger_glue_job(glue_client, bucket_name, 'data/users.csv', 'data/calories_burned.csv')
        else:
            print(f"Ignored file: {object_key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }

def trigger_glue_job(glue_client, bucket_name, users_key, calories_key):
    response = glue_client.start_job_run(
        JobName='fitness-health-etl',
        Arguments={
            '--S3_BUCKET': bucket_name,
            '--SOURCE_USERS_KEY': users_key,
            '--SOURCE_CALORIES_KEY': calories_key,
            '--DESTINATION_KEY': 'data/transformed/',
            '--DESTINATION_CSV_KEY': 'data/transformed/'
        }
    )
    
    print(f"Started Glue job: {response['JobRunId']}")
    return response
