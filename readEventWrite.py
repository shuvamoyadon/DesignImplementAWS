import boto3
import json

s3 = boto3.client('s3')


def lambda_handler(event, context):
    # Get the source bucket and key from the S3 event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']

    # Extract the filename from the object key
    filename = source_key.split('/')[-1]

    # Read the JSON file from the source bucket
    response = s3.get_object(Bucket=source_bucket, Key=source_key)
    json_data = response['Body'].read().decode('utf-8')

    # Parse the JSON data
    parsed_json = json.loads(json_data)

    # Upload the JSON data to the destination bucket
    s3.put_object(Bucket=source_bucket, Key=f'target/{filename}', Body=json.dumps(parsed_json))

    return {
        'statusCode': 200,
        'body': json.dumps('JSON file copied successfully!')
    }
